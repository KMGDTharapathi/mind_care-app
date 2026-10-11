ï»¿"""Evaluate the local MindCare Willow model server against processed test sets.

Computes:
- Safety classification (crisis/safe): confusion matrix, precision/recall/F1 per class,
  macro/weighted averages, accuracy. Ground truth from datasets/processed/{en,si}/test.jsonl
  (safety == "refer-to-professional" => crisis; else safe).
- Generation quality (vs reference output): exact match, average bigram overlap,
  average reply length, clinical-echo hits (non-crisis replies), source distribution.

Usage:
  python server/eval_model_server.py
  python server/eval_model_server.py --api http://localhost:8000/chat
  python server/eval_model_server.py --lang en --limit 100
  python server/eval_model_server.py --by-lang --probes 300
"""
import argparse
import json
import os
import random
import re
import sys
from typing import Dict, List, Optional, Tuple

import requests

PROC = os.path.normpath(
    os.path.join(os.path.dirname(__file__), "..", "ml", "data", "processed")
)
if not os.path.isdir(PROC):
    # Fallback to Models repo if present
    PROC_FALLBACK = r"F:\Models\datasets\processed"
    PROC = PROC_FALLBACK if os.path.isdir(PROC_FALLBACK) else PROC

ECHO_TERMS = [
    "stress",
    "stressed",
    "anxiety",
    "anxious",
    "depression",
    "depress",
    "burnout",
    "burned out",
    "burnt out",
    "feeling down",
    "panic attack",
    "disorder",
    "diagnos",
    "clinical",
    "tension",
    "angst",
]

CRISIS_LABEL = "refer-to-professional"


def load_split(lang: str, name: str) -> List[Dict]:
    path = os.path.join(PROC, lang, f"{name}.jsonl")
    rows: List[Dict] = []
    try:
        with open(path, "r", encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    rows.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
    except FileNotFoundError:
        pass
    return rows


def ngrams(text: str, n: int) -> set:
    words = text.lower().split()
    if len(words) < n:
        return set()
    return set(" ".join(words[i : i + n]) for i in range(len(words) - n + 1))


def bigram_overlap(a: str, b: str) -> float:
    ng_a = ngrams(a, 2)
    ng_b = ngrams(b, 2)
    if len(ng_a) == 0 and len(ng_b) == 0:
        return 1.0
    inter = len(ng_a & ng_b)
    denom = max(len(ng_a), 1)
    return inter / denom if denom > 0 else 0.0


def clinical_echo_hits(reply: str) -> int:
    low = reply.lower()
    hits = 0
    for w in ECHO_TERMS:
        if re.search(r"\b" + re.escape(w) + r"\b", low):
            hits += 1
    return hits


def classify_safe_crisis(safety_val) -> str:
    if safety_val is None:
        return "safe"
    s = str(safety_val).strip().lower()
    if s == CRISIS_LABEL or s == "crisis" or s == "refer_to_professional":
        return "crisis"
    return "safe"


def metrics_safe_crisis(tp: int, fp: int, tn: int, fn: int) -> Dict:
    safe_support = tn + fp
    crisis_support = tp + fn

    def m(correct: int, predicted: int, support: int) -> Tuple[float, float, float]:
        prec = correct / max(predicted, 1)
        rec = correct / max(support, 1)
        f1 = 2 * prec * rec / max(prec + rec, 1e-9)
        return prec, rec, f1

    sp, sr, sf = m(tn, tn + fn, safe_support)
    cp, cr, cf = m(tp, tp + fp, crisis_support)
    n = safe_support + crisis_support
    macro_prec = (sp + cp) / 2
    macro_rec = (sr + cr) / 2
    macro_f1 = (sf + cf) / 2
    weighted_prec = (sp * safe_support + cp * crisis_support) / max(n, 1)
    weighted_rec = (sr * safe_support + cr * crisis_support) / max(n, 1)
    weighted_f1 = (sf * safe_support + cf * crisis_support) / max(n, 1)
    acc = (tp + tn) / max(n, 1)

    return {
        "tp": tp,
        "fp": fp,
        "tn": tn,
        "fn": fn,
        "n": n,
        "accuracy": round(acc, 4),
        "safe": {
            "precision": round(sp, 4),
            "recall": round(sr, 4),
            "f1": round(sf, 4),
            "support": safe_support,
        },
        "crisis": {
            "precision": round(cp, 4),
            "recall": round(cr, 4),
            "f1": round(cf, 4),
            "support": crisis_support,
        },
        "macro": {
            "precision": round(macro_prec, 4),
            "recall": round(macro_rec, 4),
            "f1": round(macro_f1, 4),
            "support": n,
        },
        "weighted": {
            "precision": round(weighted_prec, 4),
            "recall": round(weighted_rec, 4),
            "f1": round(weighted_f1, 4),
            "support": n,
        },
    }


def call_server(api: str, lang: str, message: str, history: Optional[List[Dict]] = None) -> Dict:
    payload = {"message": message, "lang": lang}
    if history:
        payload["history"] = history
    try:
        resp = requests.post(api, json=payload, timeout=30)
    except Exception as e:
        return {"ok": False, "error": str(e)}
    try:
        data = resp.json()
    except Exception:
        data = {"raw": resp.text}
    return {"ok": resp.statusCode == 200, "status": resp.statusCode, "data": data}


def print_report_block(title: str, m: Dict):
    print(f"\n=== {title} ===")
    print(
        "confusion: tp=%d fp=%d tn=%d fn=%d (n=%d)"
        % (m["tp"], m["fp"], m["tn"], m["fn"], m["n"])
    )
    print("accuracy: %.4f" % m["accuracy"])
    print(
        "%-8s %9s %9s %9s %9s"
        % ("class", "precision", "recall", "f1-score", "support")
    )
    s = m["safe"]
    c = m["crisis"]
    ma = m["macro"]
    we = m["weighted"]
    print("%-8s %9.4f %9.4f %9.4f %9d" % ("safe", s["precision"], s["recall"], s["f1"], s["support"]))
    print("%-8s %9.4f %9.4f %9.4f %9d" % ("crisis", c["precision"], c["recall"], c["f1"], c["support"]))
    print("%-8s %9.4f %9.4f %9.4f %9d" % ("macro", ma["precision"], ma["recall"], ma["f1"], ma["support"]))
    print("%-8s %9.4f %9.4f %9.4f %9d" % ("weighted", we["precision"], we["recall"], we["f1"], we["support"]))


def eval_generation(api: str, lang: str, rows: List[Dict], limit: Optional[int] = None) -> Dict:
    if limit:
        rows = rows[:limit]
    exact = 0
    sims_sum = 0.0
    lens = []
    src_counts: Dict[str, int] = {}
    echo_hits_total = 0
    errors = 0
    for row in rows:
        msg = row.get("instruction") or row.get("input") or row.get("msg") or ""
        ref = row.get("output") or row.get("target") or row.get("label") or ""
        safety_gt = classify_safe_crisis(row.get("safety"))
        r = call_server(api, lang, msg)
        if not r.get("ok"):
            errors += 1
            continue
        data = r.get("data") or {}
        resp_text = data.get("response") or data.get("reply") or data.get("text") or ""
        # infer source if present (optional)
        src = data.get("source") or data.get("engine") or "server"
        src_counts[src] = src_counts.get(src, 0) + 1
        if ref and resp_text == ref:
            exact += 1
        sims_sum += bigram_overlap(resp_text, ref) if ref else 0.0
        lens.append(len(resp_text))
        if safety_gt != "crisis":
            echo_hits_total += clinical_echo_hits(resp_text)
    n = len(rows) - errors
    if n == 0:
        return {
            "lang": lang,
            "n": 0,
            "errors": errors,
            "exact_match": 0.0,
            "avg_bigram_overlap": 0.0,
            "avg_reply_len": 0.0,
            "clinical_echo_hits": 0,
            "sources": src_counts,
        }
    return {
        "lang": lang,
        "n": n,
        "errors": errors,
        "exact_match": round(exact / n, 4),
        "avg_bigram_overlap": round(sims_sum / n, 4),
        "avg_reply_len": round(sum(lens) / n, 2),
        "clinical_echo_hits": echo_hits_total,
        "sources": src_counts,
    }


def eval_safety(api: str, lang: str, rows: List[Dict], limit: Optional[int] = None) -> Dict:
    if limit:
        rows = rows[:limit]
    tp = fp = tn = fn = 0
    errors = 0
    for row in rows:
        msg = row.get("instruction") or row.get("input") or row.get("msg") or ""
        safety_gt = classify_safe_crisis(row.get("safety"))
        r = call_server(api, lang, msg)
        if not r.get("ok"):
            errors += 1
            continue
        data = r.get("data") or {}
        verdict = data.get("safety") or data.get("verdict") or data.get("risk") or "safe"
        v = str(verdict).strip().lower()
        if v == "crisis" or v == "refer-to-professional" or v == "high":
            v_cls = "crisis"
        else:
            v_cls = "safe"
        if v_cls == "crisis" and safety_gt == "crisis":
            tp += 1
        elif v_cls == "crisis" and safety_gt == "safe":
            fp += 1
        elif v_cls == "safe" and safety_gt == "safe":
            tn += 1
        else:  # fn
            fn += 1
    m = metrics_safe_crisis(tp, fp, tn, fn)
    m["errors"] = errors
    m["lang"] = lang
    return m


def main():
    ap = argparse.ArgumentParser(description="Evaluate local model server")
    ap.add_argument("--api", default="http://localhost:8000/chat", help="Chat endpoint")
    ap.add_argument("--lang", default=None, choices=["en", "si"])
    ap.add_argument("--split", default="test")
    ap.add_argument("--limit", type=int, default=None)
    ap.add_argument("--probes", type=int, default=None, help="Alias for --limit")
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--by-lang", action="store_true")
    args = ap.parse_args()

    random.seed(args.seed)
    limit = args.probes if args.probes is not None else args.limit
    langs = [args.lang] if args.lang else ["en", "si"]

    # Safety (balanced-ish by sampling similar to classification_report style optional; but use full split up to limit)
    all_safety = []
    for lang in langs:
        rows = load_split(lang, args.split)
        if limit:
            crisis = [r for r in rows if classify_safe_crisis(r.get("safety")) == "crisis"]
            safe = [r for r in rows if classify_safe_crisis(r.get("safety")) == "safe"]
            take_c = min(len(crisis), max(1, limit // 2))
            take_s = min(len(safe), limit - take_c)
            sample = crisis[:take_c] + random.sample(safe, take_s) if take_s > 0 else crisis[:take_c]
        else:
            sample = rows
        res_s = eval_safety(args.api, lang, sample)
        print_report_block(f"SAFETY {lang.upper()} (n={res_s['n']}, errors={res_s['errors']})", res_s)
        all_safety.append(res_s)

    if len(all_safety) > 1:
        tp = sum(x["tp"] for x in all_safety)
        fp = sum(x["fp"] for x in all_safety)
        tn = sum(x["tn"] for x in all_safety)
        fn = sum(x["fn"] for x in all_safety)
        m_all = metrics_safe_crisis(tp, fp, tn, fn)
        print_report_block("SAFETY OVERALL", m_all)

    print("\n--- GENERATION ---")
    gen_results = []
    for lang in langs:
        rows = load_split(lang, args.split)
        gr = eval_generation(args.api, lang, rows, limit=limit)
        gen_results.append(gr)
        print(json.dumps(gr, ensure_ascii=False, indent=2))

    if len(gen_results) > 1:
        tot_n = sum(g["n"] for g in gen_results)
        if tot_n > 0:
            em = sum(g["exact_match"] * g["n"] for g in gen_results) / tot_n
            bo = sum(g["avg_bigram_overlap"] * g["n"] for g in gen_results) / tot_n
            al = sum(g["avg_reply_len"] * g["n"] for g in gen_results) / tot_n
            eh = sum(g["clinical_echo_hits"] for g in gen_results)
            src = {}
            for g in gen_results:
                for k, v in (g["sources"] or {}).items():
                    src[k] = src.get(k, 0) + v
            overall = {
                "n": tot_n,
                "exact_match": round(em, 4),
                "avg_bigram_overlap": round(bo, 4),
                "avg_reply_len": round(al, 2),
                "clinical_echo_hits": eh,
                "sources": src,
            }
            print("\nGENERATION OVERALL:")
            print(json.dumps(overall, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
