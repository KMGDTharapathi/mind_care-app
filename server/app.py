#!/usr/bin/env python3
"""MindCare Willow model server (local merged checkpoints).

Serves the fine-tuned Qwen2.5 mental-health models behind the exact contract
the Flutter app already speaks:

    GET  /health   -> {"status": "ok", "langs": ["en", "si"]}
    POST /chat     body {"message": "...",
                         "lang": "en" | "si" | "" (auto-detect),
                         "history": [{"role": "user"|"model", "content": "..."}],
                         "mind_state": "..."}
                   -> {"response": "...", "recommendations": []}

It loads one already-merged Hugging Face checkpoint per language (no PEFT
adapters), so it works straight off the folders produced by the training
pipeline (e.g. server/models_dl/mh-qwen-en-merged).

The app owns the crisis guardrail: it never forwards a crisis message to this
server, so the model only ever handles non-crisis text.

Environment overrides:
  SRV_EN_MODEL         EN checkpoint dir   (default: models_dl/mh-qwen-en-merged)
  SRV_SI_MODEL         SI checkpoint dir   (default: models_dl/mh-qwen-si-merged)
  SRV_HOST             bind host           (default: 0.0.0.0)
  SRV_PORT             port                (default: 8000)
  SRV_MAX_NEW_TOKENS   reply length cap    (default: 64)
  SRV_TEMPERATURE      sampling temp       (default: 0.7)
  SRV_MODELS_DIR       folder holding the checkpoints
                       (default: ./models_dl next to this file)

Run:
    python server/app.py
or:
    uvicorn server.app:app --host 0.0.0.0 --port 8000
"""
import asyncio
import os
import re
import sys
import threading
from pathlib import Path

import torch
import uvicorn
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from transformers import AutoModelForCausalLM, AutoTokenizer

# System prompts must match the ones used when the adapters were trained.
SYSTEM_PROMPTS = {
    "en": (
        "You are a supportive, friendly, calm and heartfelt mental-health assistant "
        "for young people. Always reply directly and briefly to what the user says. "
        "Keep every reply to 1-3 short, warm, reassuring sentences. "
        "Never use clinical labels. NEVER mention or suggest suicide, self-harm, crisis, "
        "danger, depression, or any dark or upsetting topic. "
        "Always focus on hope, calm, and small positive steps."
    ),
    "si": (
        "ඔබ තරුණයින්ට සහායෝගය දෙන මෘදු, සන්සුන් සහායකයෙකි. "
        "පිළිතුරු වාක්‍ය 1-3ක් තුළ කෙටිව, උණුසුම්, "
        "අනුකම්පාසහිතව තබාගන්න. ක්ලිනිකල් මාතෘකා භාවිතා "
        "නොකරන්න. සියදිවි නසාගැනීම, මරණය, අනතුරු වැනි "
        "අඳුරු කරුණු කිසිවිටෙක සඳහන් නොකරන්න. සැමවිටම "
        "බලාපොරොත්තුව සහ කුඩා ධනාත්මක පියවර ගැන කතා කරන්න."
    ),
}


MAX_NEW_TOKENS = int(os.environ.get("SRV_MAX_NEW_TOKENS", "160"))
TEMPERATURE = float(os.environ.get("SRV_TEMPERATURE", "0.45"))
PORT = int(os.environ.get("SRV_PORT", "8000"))
HOST = os.environ.get("SRV_HOST", "0.0.0.0")
HF_FALLBACK_MODEL = os.environ.get(
    "SRV_HF_FALLBACK_MODEL", "Dakshina-mentalHealth/mh-sin-sft-1b"
)

app = FastAPI(title="MindCare Willow API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

TOKENIZERS = {}
MODELS = {}
GENERATE_KW = {}
_INFER_LOCK = threading.Lock()

_IGNORE_HISTORY_SUBSTRINGS = (
    "having trouble reaching my mind",
    "මගේ මනසට ළඟා වෙන්න",
    "1926",
    "1929",
)


def _resolve_models_dir() -> Path:
    env = os.environ.get("SRV_MODELS_DIR")
    if env:
        return Path(env)
    return Path(__file__).resolve().parent / "models_dl"


def _model_path(env_name: str, folder: str) -> str:
    explicit = os.environ.get(env_name)
    if explicit:
        return explicit
    return str(_resolve_models_dir() / folder)


def _detect_lang(text: str) -> str:
    """'si' when the message is predominantly Sinhala script, else 'en'."""
    runes = [ord(c) for c in text]
    sinhala = sum(1 for r in runes if 0x0D80 <= r <= 0x0DFF)
    latin = sum(1 for r in runes if 0x41 <= r <= 0x5A or 0x61 <= r <= 0x7A)
    letters = sinhala + latin
    if letters and sinhala / letters >= 0.35:
        return "si"
    return "en"


def _has_weight_files(folder: Path) -> bool:
    if not folder.is_dir():
        return False
    for pattern in ("*.safetensors", "*.bin"):
        if any(folder.glob(pattern)):
            return True
    return False


def _clean_reply(text: str, lang: str) -> str:
    """Strip leaked template tokens and trim incomplete trailing fragments."""
    cleaned = text or ""
    for marker in ("<|im_end|>", "<|im_start|>", "<|endoftext|>"):
        if marker in cleaned:
            cleaned = cleaned.split(marker, 1)[0]
    cleaned = re.sub(r"^(assistant|model|system|user)\s*[:\-]?\s*", "", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    if not cleaned:
        return ""

    # If the reply does not end with terminal punctuation, check if it was cut
    # off mid-sentence after at least one complete sentence.
    if cleaned[-1] not in ".!?।\"')”’💙🌿😊💚":
        last_punct = max(cleaned.rfind("."), cleaned.rfind("!"), cleaned.rfind("?"), cleaned.rfind("।"))
        if last_punct >= 24:
            cleaned = cleaned[: last_punct + 1].strip()
        else:
            cleaned = cleaned.rstrip(",;:-— ") + "."
    return cleaned


def _is_usable_reply(text: str, lang: str, user_msg: str = "") -> bool:
    """Verify the generated reply is coherent, in the target language, and non-empty."""
    s = text.strip()
    if len(s) < 8:
        return False
    if "\ufffd" in s or "#" in s or "&" in s:
        return False
    if user_msg and s.lower() == user_msg.strip().lower():
        return False

    runes = [ord(c) for c in s]
    sinhala = sum(1 for r in runes if 0x0D80 <= r <= 0x0DFF)
    latin = sum(1 for r in runes if (0x41 <= r <= 0x5A) or (0x61 <= r <= 0x7A))
    letters = sinhala + latin
    if letters < 4:
        return False

    if lang == "si":
        if sinhala / letters < 0.6:
            return False
        # Reject digits glued directly inside Sinhala words
        for i, r in enumerate(runes):
            if 0x30 <= r <= 0x39:
                prev_si = i > 0 and (0x0D80 <= runes[i - 1] <= 0x0DFF)
                next_si = i < len(runes) - 1 and (0x0D80 <= runes[i + 1] <= 0x0DFF)
                if prev_si or next_si:
                    return False
    else:
        if latin / letters < 0.7:
            return False

    return True


def _sanitize_history(raw_history: list, lang: str, current_message: str) -> list:
    """Keep only recent, clean turns in the same language so the 0.5B model stays on-distribution."""
    filtered = []
    for turn in (raw_history or [])[-6:]:
        if not isinstance(turn, dict):
            continue
        role = "user" if str(turn.get("role", "user")) == "user" else "assistant"
        content = str(turn.get("content", "")).strip()
        if not content or len(content) > 400:
            continue
        low = content.lower()
        if any(bad in low for bad in _IGNORE_HISTORY_SUBSTRINGS):
            continue
        if _detect_lang(content) != lang:
            continue
        if content == current_message:
            continue
        # Enforce alternating roles starting with 'user'
        if not filtered:
            if role != "user":
                continue
            filtered.append({"role": role, "content": content})
        else:
            if filtered[-1]["role"] == role:
                filtered[-1]["content"] = content
            else:
                filtered.append({"role": role, "content": content})

    # Drop trailing 'user' if present so we can append the current user message cleanly
    if filtered and filtered[-1]["role"] == "user":
        filtered.pop()

    # Keep at most the last 2 full turns (4 messages: 2 user + 2 assistant)
    return filtered[-4:]


def _run_model_once(lang: str, messages: list, gen_overrides: dict | None = None) -> str:
    tokenizer = TOKENIZERS[lang]
    model = MODELS[lang]

    prompt = tokenizer.apply_chat_template(
        messages, tokenize=False, add_generation_prompt=True
    )
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)

    kw = dict(GENERATE_KW)
    kw["pad_token_id"] = tokenizer.pad_token_id
    kw["eos_token_id"] = tokenizer.eos_token_id
    if gen_overrides:
        kw.update(gen_overrides)

    with torch.inference_mode():
        out = model.generate(**inputs, **kw)

    new_tokens = out[0][inputs["input_ids"].shape[1]:]
    raw_text = tokenizer.decode(new_tokens, skip_special_tokens=True)
    return _clean_reply(raw_text, lang)


def _generate_sync(lang: str, message: str, raw_history: list) -> str:
    with _INFER_LOCK:
        sys_msg = {"role": "system", "content": SYSTEM_PROMPTS[lang]}
        clean_hist = _sanitize_history(raw_history, lang, message)

        # Attempt 1: with recent sanitized history and balanced sampling
        messages = [sys_msg, *clean_hist, {"role": "user", "content": message}]
        reply = _run_model_once(lang, messages)
        if _is_usable_reply(reply, lang, message):
            return reply

        # Attempt 2: single-turn (no history) with lower temperature for stability
        single_turn = [sys_msg, {"role": "user", "content": message}]
        reply = _run_model_once(
            lang,
            single_turn,
            {
                "do_sample": True,
                "temperature": 0.25,
                "top_p": 0.85,
                "top_k": 25,
                "repetition_penalty": 1.2,
            },
        )
        if _is_usable_reply(reply, lang, message):
            return reply

        # Attempt 3: deterministic greedy decoding on single-turn
        reply = _run_model_once(
            lang,
            single_turn,
            {
                "do_sample": False,
                "repetition_penalty": 1.2,
            },
        )
        return reply


def load_model(lang: str, path: str) -> None:
    folder = Path(path)
    has_local_weights = _has_weight_files(folder)
    source = path if has_local_weights else HF_FALLBACK_MODEL
    local_only = has_local_weights

    if not has_local_weights:
        print(
            "[serve] local weights (*.safetensors) not found in %s (gitignored); "
            "loading %s from Hugging Face cache/hub ..." % (path, source)
        )
    else:
        print("[serve] loading %s model from %s ..." % (lang, source))
    sys.stdout.flush()

    tokenizer_src = path if folder.is_dir() else source
    tokenizer = AutoTokenizer.from_pretrained(tokenizer_src, local_files_only=local_only)
    if tokenizer.pad_token is None or tokenizer.pad_token_id == tokenizer.eos_token_id:
        tokenizer.pad_token = tokenizer.eos_token

    model = AutoModelForCausalLM.from_pretrained(
        source,
        torch_dtype=torch.float32,
        local_files_only=local_only,
        low_cpu_mem_usage=True,
    )
    model.eval()

    TOKENIZERS[lang] = tokenizer
    MODELS[lang] = model
    print("[serve] %s model ready" % lang)
    sys.stdout.flush()


def load_all() -> None:
    torch.set_num_threads(max(1, (os.cpu_count() or 4)))

    en_path = _model_path("SRV_EN_MODEL", "mh-qwen-en-merged")
    si_path = _model_path("SRV_SI_MODEL", "mh-qwen-si-merged")

    load_model("en", en_path)
    # A bilingual build or fallback may point both languages at the same checkpoint.
    same_path = os.path.normcase(si_path) == os.path.normcase(en_path)
    both_fallback = (not _has_weight_files(Path(en_path))) and (
        not _has_weight_files(Path(si_path))
    )
    if same_path or both_fallback:
        MODELS["si"] = MODELS["en"]
        TOKENIZERS["si"] = TOKENIZERS["en"]
        print("[serve] si model sharing loaded checkpoint")
    else:
        load_model("si", si_path)

    global GENERATE_KW
    GENERATE_KW = dict(
        max_new_tokens=MAX_NEW_TOKENS,
        do_sample=True,
        temperature=TEMPERATURE,
        top_p=0.88,
        top_k=40,
        repetition_penalty=1.15,
        no_repeat_ngram_size=4,
        pad_token_id=TOKENIZERS["en"].pad_token_id,
        eos_token_id=TOKENIZERS["en"].eos_token_id,
    )
    print("[serve] ready, langs: %s" % sorted(MODELS))
    sys.stdout.flush()


@app.on_event("startup")
async def _startup() -> None:
    if not MODELS:
        load_all()


@app.get("/health")
async def health():
    return {"status": "ok", "langs": sorted(MODELS), "version": 2}


@app.post("/chat")
async def chat(request: Request):
    body = await request.json()
    message = str(body.get("message", "")).strip()
    if not message:
        return {"response": "", "recommendations": []}

    lang = str(body.get("lang", "")).strip().lower()
    if lang not in ("en", "si"):
        lang = _detect_lang(message)

    raw_history = body.get("history") or []
    text = await asyncio.to_thread(_generate_sync, lang, message, raw_history)

    return {"response": text, "recommendations": []}


@app.get("/")
def index():
    return {
        "service": "MindCare Willow API",
        "endpoints": ["/health", "/chat"],
        "langs": sorted(MODELS),
        "version": 2,
    }


if __name__ == "__main__":
    load_all()
    print("[serve] listening on http://%s:%d" % (HOST, PORT))
    sys.stdout.flush()
    uvicorn.run(app, host=HOST, port=PORT)
