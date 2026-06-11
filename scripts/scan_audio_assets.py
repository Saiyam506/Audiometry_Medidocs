#!/usr/bin/env python3
"""
Scan audio assets under assets/audio, detect header signatures, and flag suspicious files.
Writes a JSON report to scripts/audio_asset_report.json and prints a summary.
"""
import os
import json

ROOT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')
REPORT = os.path.join(os.path.dirname(__file__), 'audio_asset_report.json')

SIGNATURES = {
    'wav': [b'RIFF'],
    'mp3': [b'ID3', b'\xFF\xFB', b'\xFF\xF3', b'\xFF\xF2'],
    'flac': [b'fLaC'],
}

suspicious = []
all_files = []

for dirpath, dirnames, filenames in os.walk(ROOT):
    for fname in filenames:
        path = os.path.join(dirpath, fname)
        rel = os.path.relpath(path, os.path.dirname(__file__) + os.sep + '..')
        try:
            size = os.path.getsize(path)
            with open(path, 'rb') as f:
                head = f.read(16)
            detected = 'unknown'
            for k, sigs in SIGNATURES.items():
                for sig in sigs:
                    if head.startswith(sig):
                        detected = k
                        break
                if detected != 'unknown':
                    break
            ext = os.path.splitext(fname)[1].lower().lstrip('.')
            ok = True
            notes = []
            if ext == 'mp3' and detected != 'mp3':
                ok = False
                notes.append(f'extension mp3 but header={detected}')
            if ext == 'wav' and detected != 'wav':
                ok = False
                notes.append(f'extension wav but header={detected}')
            if size < 1024:
                ok = False
                notes.append(f'size small ({size} bytes)')
            entry = {
                'path': rel.replace('\\', '/'),
                'size': size,
                'ext': ext,
                'detected': detected,
                'ok': ok,
                'notes': notes,
            }
            all_files.append(entry)
            if not ok:
                suspicious.append(entry)
        except Exception as e:
            all_files.append({'path': rel.replace('\\', '/'), 'error': str(e)})

report = {
    'scanned_at': os.path.getmtime(__file__),
    'total_files': len(all_files),
    'suspicious_count': len(suspicious),
    'suspicious': suspicious,
    'files': all_files,
}

with open(REPORT, 'w', encoding='utf-8') as f:
    json.dump(report, f, indent=2)

print(f'Scanned {len(all_files)} files, {len(suspicious)} suspicious files. Report written to {REPORT}')
