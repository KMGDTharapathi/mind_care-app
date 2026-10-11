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
pipeline (e.g. F:\\Models\\models_dl\\mh-qwen-en-merged).

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
                       (default: F:\\Models\\models_dl, else ./models_dl)

Run:
    python server/app.py
or:
    uvicorn server.app:app --host 0.0.0.0 --port 8000
"""
import os
import re
import sys
from pathlib import Path

import torch
import uvicorn
from fastapi import FastAPI, Request
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


MAX_NEW_TOKENS = int(os.environ.get("SRV_MAX_NEW_TOKENS", "64"))
TEMPERATURE = float(os.environ.get("SRV_TEMPERATURE", "0.7"))
PORT = int(os.environ.get("SRV_PORT", "8000"))
HOST = os.environ.get("SRV_HOST", "0.0.0.0")

app = FastAPI(title="MindCare Willow API")

TOKENIZERS = {}
MODELS = {}
GENERATE_KW = {}


def _resolve_models_dir() -> Path:
    env = os.environ.get("SRV_MODELS_DIR")
    if env:
        return Path(env)
    default = Path(r"F:\Models\models_dl")
    if default.is_dir():
        return default
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
    if letters and sinhala / letters >= 0.5:
        return "si"
    return "en"


def load_model(lang: str, path: str) -> None:
    if not Path(path).is_dir():
        raise FileNotFoundError(
            "Model folder not found: %s\n"
            "Set SRV_%s_MODEL or SRV_MODELS_DIR to the checkpoint folder."
            % (path, lang.upper())
        )

    print("[serve] loading %s model from %s ..." % (lang, path))
    sys.stdout.flush()

    tokenizer = AutoTokenizer.from_pretrained(path, local_files_only=True)
    if tokenizer.pad_token is None or tokenizer.pad_token_id == tokenizer.eos_token_id:
        tokenizer.pad_token = tokenizer.eos_token

    model = AutoModelForCausalLM.from_pretrained(
        path,
        torch_dtype=torch.float32,
        local_files_only=True,
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
    # A bilingual build may point both languages at the same checkpoint.
    if os.path.normcase(si_path) == os.path.normcase(en_path):
        MODELS["si"] = MODELS["en"]
        TOKENIZERS["si"] = TOKENIZERS["en"]
    else:
        load_model("si", si_path)

    global GENERATE_KW
    GENERATE_KW = dict(
        max_new_tokens=MAX_NEW_TOKENS,
        do_sample=True,
        temperature=TEMPERATURE,
        top_p=0.9,
        repetition_penalty=1.1,
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
    return {"status": "ok", "langs": sorted(MODELS)}


@app.post("/chat")
async def chat(request: Request):
    body = await request.json()
    message = str(body.get("message", "")).strip()
    if not message:
        return {"response": "", "recommendations": []}

    lang = str(body.get("lang", "")).strip().lower()
    if lang not in ("en", "si"):
        lang = _detect_lang(message)

    tokenizer = TOKENIZERS[lang]
    model = MODELS[lang]

    messages = [{"role": "system", "content": SYSTEM_PROMPTS[lang]}]
    for turn in (body.get("history") or [])[-10:]:
        role = str(turn.get("role", "user"))
        role = "user" if role == "user" else "assistant"
        content = str(turn.get("content", "")).strip()
        if content:
            messages.append({"role": role, "content": content})
    messages.append({"role": "user", "content": message})

    prompt = tokenizer.apply_chat_template(
        messages, tokenize=False, add_generation_prompt=True
    )
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)

    with torch.inference_mode():
        out = model.generate(**inputs, **GENERATE_KW)

    new_tokens = out[0][inputs["input_ids"].shape[1]:]
    text = tokenizer.decode(new_tokens, skip_special_tokens=True).strip()

    return {"response": text, "recommendations": []}


@app.get("/")
def index():
    return {
        "service": "MindCare Willow API",
        "endpoints": ["/health", "/chat"],
        "langs": sorted(MODELS),
    }


if __name__ == "__main__":
    load_all()
    print("[serve] listening on http://%s:%d" % (HOST, PORT))
    sys.stdout.flush()
    uvicorn.run(app, host=HOST, port=PORT)
