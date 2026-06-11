"""
Generate TTS audio placeholders for the WRS word banks.
Uses pyttsx3 (offline TTS). Run:

    python -m pip install pyttsx3
    python scripts/generate_tts.py

This will write WAV files under assets/audio/{en,hi,kn,te}/
"""
from pathlib import Path
import pyttsx3

LANG_BANKS = {
    'en': [
        'Apple', 'Water', 'School', 'Garden', 'Window', 'Tree', 'Book', 'Chair', 'Door', 'House',
        'Flower', 'River', 'Mountain', 'Computer', 'Phone', 'Bottle', 'Table', 'Pencil', 'Notebook', 'Bus',
        'Train', 'Market', 'Hospital', 'Doctor', 'Teacher',
    ],
    'hi': ['सेब', 'पानी', 'स्कूल', 'बगीचा', 'खिड़की', 'पेड़', 'किताब', 'कुर्सी', 'दरवाज़ा', 'घर'],
    'kn': ['ಏಪಲ್', 'ನೀರಿನ', 'ಶಾಲೆ', 'ತೋಟ', 'ಕಿಟಕಿ', 'ಮರ', 'ಪುಸ್ತಕ', 'ಕುರ್ಚಿ', 'ದ್ವಾರ', 'ಮನೆ'],
    'te': ['ఆపిల్', 'నీరు', 'పాఠశాల', 'తోట', 'కిటికీ', 'చెట్టు', 'పుస్తకం', 'కుర్చీ', 'ద్వారం', 'ఇల్లు'],
}

OUT = Path('assets') / 'audio'
OUT.mkdir(parents=True, exist_ok=True)

engine = pyttsx3.init()
# Optional: set properties (rate, volume)
engine.setProperty('rate', 160)

for lang, words in LANG_BANKS.items():
    lang_dir = OUT / lang
    lang_dir.mkdir(parents=True, exist_ok=True)
    for w in words:
        # create filename friendly
        name = w if all(ord(c) < 128 for c in w) else ''.join(
            [f"u{ord(c):x}" for c in w])
        filename = lang_dir / f"{name}.wav"
        print(f"Generating {filename} ('{w}')")
        engine.save_to_file(w, str(filename))

engine.runAndWait()
print('Done')
