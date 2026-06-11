"""
Simple end-to-end test: POSTs a sample hearing report to the backend and
checks for a Base64 PDF in the response.

Usage:
    python backend/test_e2e.py --url http://127.0.0.1:8001/hearing/report

Note: backend must be running for this to succeed.
"""
import argparse
import json
import sys
import base64

import requests

SAMPLE = {
    "patient_name": "E2E Test",
    "patient_age": 45,
    "patient_gender": "Other",
    "wrs_language": "English",
    "left_ear": {"hz_500": 20, "hz_1000": 25, "hz_2000": 30, "hz_4000": 35},
    "right_ear": {"hz_500": 25, "hz_1000": 30, "hz_2000": 35, "hz_4000": 40},
    "wrs_answers": [{"word_id": i+1, "is_correct": True} for i in range(10)]
}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--url', default='http://127.0.0.1:8001/hearing/report')
    args = parser.parse_args()

    try:
        resp = requests.post(args.url, json=SAMPLE, timeout=10)
    except Exception as e:
        print('Request failed:', e)
        sys.exit(2)

    if resp.status_code != 200:
        print('Server returned', resp.status_code)
        print(resp.text)
        sys.exit(3)

    data = resp.json()
    pdf_b64 = data.get('pdf_base64', '')
    if not pdf_b64:
        print(
            'No PDF returned (pdf_base64 empty). Server may not have wkhtmltopdf installed.')
        sys.exit(4)

    try:
        pdf = base64.b64decode(pdf_b64)
        print('Received PDF (bytes):', len(pdf))
        out = 'backend/e2e_report.pdf'
        with open(out, 'wb') as f:
            f.write(pdf)
        print('Wrote', out)
    except Exception as e:
        print('Failed to decode/write PDF:', e)
        sys.exit(5)

    print('E2E test succeeded')


if __name__ == '__main__':
    main()
