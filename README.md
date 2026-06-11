# hearing_aid

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## Hearing Assessment Module (this repo)

The codebase includes a Flutter client (`lib/`) and a FastAPI backend (`backend/`) implementing PTA and WRS features.

Quick run (Flutter):

```bash
flutter pub get
flutter run
```

Backend notes:
- Use Python 3.11 for compatibility with pinned Pydantic 1.10.x.
- Install dependencies in `backend/` virtualenv: `python -m pip install -r backend/requirements.txt`.
- Install `wkhtmltopdf` and ensure its `bin` folder is on PATH for PDF generation.

Assets:
- WRS audio assets are referenced under `assets/audio/<lang>/` — replace with real recordings.
- PTA tones can be added under `assets/tones/`.

If you'd like, I can add placeholder audio files and implement an automatic PTA tone-play flow next.
If you'd like, I can also append delivery instructions.

---

## Delivery & Verification

1. Flutter client

```bash
flutter pub get
flutter analyze
flutter run
```

- The Hearing Assessment screen contains PTA sliders and a "Guided PTA" automated flow (play tone, press "Heard"/"Not heard" — app will step levels using a staircase method). Use the Play button to hear tone/audio.
- When running on Android emulator, backend requests should target `http://10.0.2.2:8001` (change in code or set up port forwarding).
 - The Hearing Assessment screen contains PTA sliders and a "Guided PTA" automated flow (play tone, press "Heard"/"Not heard" — app will step levels using a staircase method). Use the Play button to hear tone/audio.
 - This project is targeted for desktop web. When running in the browser (desktop), the backend base URL `http://localhost:8001` is used and should work without emulator mappings.

2. Backend (optional)

```powershell
# create venv (Python 3.11)
py -3.11 -m venv backend\\.venv
& backend\\.venv\\Scripts\\python.exe -m pip install -r backend/requirements.txt
& backend\\.venv\\Scripts\\python.exe -m uvicorn backend.main:app --port 8001
```

- Ensure `wkhtmltopdf` is installed and available on PATH for PDF generation.

3. Verify

- Run `flutter analyze` and fix any issues reported (I kept the code null-safe and analyzer-friendly).
- Launch the app and try the Guided PTA flow and WRS audio playback to confirm assets load.

If you want, I will now:
- Run `flutter analyze` and fix any reported warnings/errors, or
- Expand the automated PTA algorithm further (auto-converge and auto-record after convergence), or
- Add multilingual WRS recordings.
 
### Quick run scripts

There are simple PowerShell helper scripts in `scripts/`:

```powershell
./scripts/run_backend.ps1
./scripts/run_flutter.ps1
```

Run the backend first, then start the Flutter app.

### Generate real-sounding audio (optional)

To generate offline TTS recordings for the WRS word banks using your local Python TTS engine (`pyttsx3`), run:

```powershell
python -m pip install pyttsx3
python scripts/generate_tts.py
```

This will create WAV files under `assets/audio/{en,hi,kn,te}/` which the app will play.

### End-to-end test

To run a quick E2E test that posts a sample report to the backend and writes the returned PDF:

```powershell
# ensure backend is running on port 8001
python backend/test_e2e.py --url http://127.0.0.1:8001/hearing/report
```

### Package release

Create a zip of the repository:

```powershell
./scripts/package_project.ps1
```

### Release

- A release zip is available at repository root: `hearing_aid_release.zip`.
- Built web artifacts are in `build/web/` (open `build/web/index.html` or serve with a simple HTTP server).

Example: serve the built web locally
```bash
python -m http.server 8000 --directory build/web
# then open http://localhost:8000
```
