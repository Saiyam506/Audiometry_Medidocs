#!/usr/bin/env python3
import json
import os
import csv
REPORT = 'audio_asset_report.json'
SRC = os.path.dirname(__file__)
report_path = os.path.join(SRC, REPORT)
out = os.path.join(SRC, 'suspicious_audio.csv')
if not os.path.exists(report_path):
    print('report not found:', report_path)
    raise SystemExit(1)
with open(report_path, 'r', encoding='utf-8') as f:
    r = json.load(f)
rows = r.get('suspicious', [])
with open(out, 'w', newline='', encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(['path', 'size', 'ext', 'detected', 'ok', 'notes'])
    for e in rows:
        notes = '; '.join(e.get('notes', []))
        w.writerow([e.get('path', ''), e.get('size', ''), e.get(
            'ext', ''), e.get('detected', ''), e.get('ok', ''), notes])
print('Wrote', out)
