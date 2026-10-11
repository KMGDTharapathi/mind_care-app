Kaggle Evaluation Instructions

1. Upload test data to Kaggle Input with structure:
   /kaggle/input/mindcare-test-data/processed/en/test.jsonl
   /kaggle/input/mindcare-test-data/processed/si/test.jsonl

2. In Kaggle notebook, create new notebook, add a single cell.
3. Copy contents of server/eval_model_server.py into that cell.
4. Before running, change:
   - API_URL = 'https://YOUR_PUBLIC_TUNNEL/chat' (not localhost)
   - PROC path - either set to '/kaggle/input/mindcare-test-data/processed' or keep the auto-detect logic.

The existing script already tries multiple fallbacks; add Kaggle paths if needed.

localhost won't work from Kaggle - use ngrok/Cloudflare Tunnel.
