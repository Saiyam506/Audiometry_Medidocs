Release Notes — Hearing Assessment Module

Version: 1.0.0
Date: 2026-05-30

Overview
- Implements Pure Tone Audiometry (PTA) and Word Recognition Score (WRS) per the provided problem statement / PDF.
- Desktop/web-first Flutter client with responsive layout using `flutter_screenutil`.
- FastAPI backend that validates payloads, computes PTA & WRS, renders a Jinja2 HTML report, and generates a Base64 PDF via `wkhtmltopdf` (using `pdfkit`).

Key Features (aligned to PDF)
- Guided PTA: automated staircase flow with play tone, "Heard" / "Not heard" buttons, auto-record after convergence (2 reversals) per frequency.
- PTA input: sliders for 500/1000/2000/4000 Hz for each ear; play-tone buttons for each frequency.
- WRS: multilingual word banks (English/Hindi/Kannada/Telugu); randomized 10-word sessions, per-word audio playback, selectable options for recognition scoring.
- Backend report: computes left/right PTA, classifies hearing loss, computes WRS percentage and overall score, returns Base64 PDF plus metrics.

Files of interest
- Flutter client: `lib/hearing_assessment.dart`, `lib/main.dart`
- Backend: `backend/main.py`, templates: `backend/templates/report.html`
- TTS generator: `scripts/generate_tts.py` (produces `assets/audio/{en,hi,kn,te}`)
- Cleanup script: `scripts/clean_audio_assets.py`
- E2E test: `backend/test_e2e.py`
- Packaging: `scripts/package_project.ps1` → produced `hearing_aid_release.zip`

Run / verify
1) Start backend (PowerShell):
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_backend.ps1
```
2) Run E2E test (verifies PDF output):
```bash
python backend/test_e2e.py --url http://127.0.0.1:8001/hearing/report
```
3) Run Flutter (web) during development:
```bash
flutter run -d chrome
```
4) Build web release:
```bash
flutter build web --release
python -m http.server 8000 --directory build/web
# open http://localhost:8000
```

Notes & next steps
- Ensure `wkhtmltopdf` is installed and available on PATH (Windows fallback path: `C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe`).
- The repository contains generated TTS WAVs and MP3 placeholders. Non-standard/generated files were moved to `assets/audio/<lang>/extras/` by `scripts/clean_audio_assets.py`.
- Optional improvements (not required by PDF): replace TTS with studio-quality recordings; prepare platform installers; host release zip on a distribution server.

Contact
- If you want any optional improvements implemented now, tell me which one and I will proceed.
