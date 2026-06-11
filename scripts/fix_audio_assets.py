#!/usr/bin/env python3
"""
Generate short WAV beep files for suspicious audio assets.
- Reads the scanner report if present, otherwise rescans assets.
- For each suspicious entry, creates a small 16-bit PCM WAV (440Hz beep, 22050Hz, 0.25s)
  at the .wav path (either overwriting a tiny/invalid .wav or creating a new .wav sibling for an .mp3 file).
"""
import os
import json
import wave
import math
import struct

ROOT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')
REPORT = os.path.join(os.path.dirname(__file__), 'audio_asset_report.json')

# Parameters for beep
SAMPLE_RATE = 22050
DURATION = 0.25
FREQ = 440.0
AMPLITUDE = 0.25  # 0..1


def generate_wav(path, freq=FREQ, duration=DURATION, sr=SAMPLE_RATE, amp=AMPLITUDE):
    n_samples = int(sr * duration)
    max_amp = int(32767 * amp)
    with wave.open(path, 'wb') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)  # 16-bit
        wf.setframerate(sr)
        for i in range(n_samples):
            t = float(i) / sr
            sample = int(max_amp * math.sin(2.0 * math.pi * freq * t))
            wf.writeframes(struct.pack('<h', sample))


def main():
    if os.path.exists(REPORT):
        with open(REPORT, 'r', encoding='utf-8') as f:
            report = json.load(f)
        suspicious = report.get('suspicious', [])
    else:
        print('Report not found; please run scripts/scan_audio_assets.py first.')
        return

    created = []
    for entry in suspicious:
        p = entry.get('path')
        if not p:
            continue
        # path is relative like assets/audio/en/apple.mp3
        full = os.path.join(os.path.dirname(__file__), '..', p)
        full = os.path.normpath(full)
        base, ext = os.path.splitext(full)
        target_wav = base + '.wav'
        try:
            # If wav already exists and is tiny (<1KB), overwrite; else create wav sibling if not exists
            should_write = False
            if os.path.exists(target_wav):
                if os.path.getsize(target_wav) < 1024:
                    should_write = True
            else:
                should_write = True

            if should_write:
                os.makedirs(os.path.dirname(target_wav), exist_ok=True)
                generate_wav(target_wav)
                created.append(os.path.relpath(
                    target_wav, os.path.dirname(__file__) + os.sep + '..'))
        except Exception as e:
            print('Failed to create WAV for', full, e)

    print(f'Created/overwrote {len(created)} WAV files as fallbacks. Example:')
    for c in created[:10]:
        print(' -', c)


if __name__ == '__main__':
    main()
