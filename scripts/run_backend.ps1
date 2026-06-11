# Run backend (Windows PowerShell)
# Requires Python 3.11 installed

py -3.11 -m venv backend\.venv
& backend\.venv\Scripts\python.exe -m pip install -r backend/requirements.txt
& backend\.venv\Scripts\python.exe -m uvicorn backend.main:app --port 8002
