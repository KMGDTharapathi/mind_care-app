# MindCare Willow model server

Local FastAPI server that runs the fine-tuned Qwen2.5 mental-health checkpoints
and answers the exact contract the Flutter app already speaks:

| Method | Path      | Body                                                   | Returns |
|--------|-----------|--------------------------------------------------------|---------|
| GET    | `/health` | –                                                      | `{"status":"ok","langs":["en","si"]}` |
| POST   | `/chat`   | `{"message":"...","lang":"en"\|"si","history":[{"role","content"}...]}` | `{"response":"...","recommendations":[]}` |

`lang` is optional – the server auto-detects Sinhala script and falls back to
English. The app remains responsible for the crisis guardrail; this model only
ever sees non-crisis text.

## 1. Run the server

```powershell
cd F:\Mind_Care\mind_care-app\server
.\run.ps1
```

The first run creates `server\.venv` and installs dependencies (torch,
transformers, fastapi, uvicorn). It then starts listening on
`0.0.0.0:8000`.

### Model location

By default it loads the already-downloaded merged checkpoints:

```
F:\Models\models_dl\mh-qwen-en-merged
F:\Models\models_dl\mh-qwen-si-merged
```

Override with environment variables:

| Variable             | Default                                  | Purpose |
|----------------------|------------------------------------------|---------|
| `SRV_MODELS_DIR`     | `F:\Models\models_dl`                    | Folder holding the checkpoints |
| `SRV_EN_MODEL`       | `<models dir>\mh-qwen-en-merged`         | English checkpoint |
| `SRV_SI_MODEL`       | `<models dir>\mh-qwen-si-merged`         | Sinhala checkpoint |
| `SRV_PORT`           | `8000`                                   | Port |
| `SRV_HOST`           | `0.0.0.0`                                | Bind address |
| `SRV_MAX_NEW_TOKENS` | `64`                                     | Reply length cap |
| `SRV_TEMPERATURE`    | `0.7`                                    | Sampling temperature |

To serve the Sinhala-only `mh-sin-sft-1b` build instead:

```powershell
$env:SRV_EN_MODEL = "F:\Models\models_dl\mh-sin-sft-1b"
$env:SRV_SI_MODEL = "F:\Models\models_dl\mh-sin-sft-1b"
.\run.ps1
```

(The model weights stay in `F:\Models`; they are **not** copied into this repo.)

## 2. Smoke test

```powershell
curl http://localhost:8000/health

curl -X POST http://localhost:8000/chat -H "Content-Type: application/json" `
  -d '{\"message\":\"I feel so stressed about my finals\"}'

curl -X POST http://localhost:8000/chat -H "Content-Type: application/json" `
  -d '{\"message\":\"මට කලබලයි\"}'
```

## 3. Point the app at it

One command starts the model server (if it isn't already up), waits for it to
finish loading, then runs the app:

```powershell
# Phone on the same Wi-Fi as this PC (auto-detects the LAN IP):
.\run-app-on-phone.ps1

# Android phone on USB (uses `adb reverse`, no Wi-Fi needed):
.\run-app-on-phone.ps1 -AdbReverse

# Also open the Windows Firewall port (run once, as admin):
.\run-app-on-phone.ps1 -OpenFirewall

# Build an installable APK instead of `flutter run`:
.\run-app-on-phone.ps1 -BuildApk
```

Prefer two terminals? Start `.\run.ps1` in one, then:

```powershell
.\run-app-on-phone.ps1 -NoServer
```

Manual equivalents, depending on where the app runs:

| Target                          | Base URL |
|---------------------------------|----------|
| Android emulator                | `http://10.0.2.2:8000` |
| iOS simulator / desktop / web   | `http://localhost:8000` |
| Physical phone (same Wi-Fi)     | `http://<PC-LAN-IP>:8000` |

```powershell
flutter run --dart-define=WILLOW_API_BASE_URL=http://192.168.1.20:8000
```

Notes:

- Cleartext HTTP is already enabled for local development
  (`android:usesCleartextTraffic="true"` and the iOS `NSAppTransportSecurity`
  exception), so the phone can talk to `http://<ip>:8000`.
- The PC firewall must allow inbound TCP 8000 (use `-OpenFirewall`, or accept
  the Windows prompt the first time Python binds the port).
- `--dart-define=WILLOW_SERVER_MODE=false` forces the in-app curated engine
  (useful for offline demos).
- When a base URL is omitted the app keeps its built-in default tunnel.

Resolution order inside the app is always: **crisis guardrail → model server →
curated fallback**.
