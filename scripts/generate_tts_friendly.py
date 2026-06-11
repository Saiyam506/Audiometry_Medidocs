"""
Generate TTS WAV files with friendly filenames (English labels) for each language.
Requires `pyttsx3` installed.
"""
from pathlib import Path
import pyttsx3

# mapping: english label -> localized text
BANKS = {
    'en': {
        'Apple': 'Apple', 'Water': 'Water', 'School': 'School', 'Garden': 'Garden', 'Window': 'Window',
        'Tree': 'Tree', 'Book': 'Book', 'Chair': 'Chair', 'Door': 'Door', 'House': 'House'
    },
    'hi': {
        'Apple': 'सेब', 'Water': 'पानी', 'School': 'स्कूल', 'Garden': 'बगीचा', 'Window': 'खिड़की',
        'Tree': 'पेड़', 'Book': 'किताब', 'Chair': 'कुर्सी', 'Door': 'दरवाज़ा', 'House': 'घर'
    },
    'kn': {
        'Apple': 'ಏಪಲ್', 'Water': 'ನೀರಿನ', 'School': 'ಶಾಲೆ', 'Garden': 'ತೋಟ', 'Window': 'ಕಿಟಕಿ',
        'Tree': 'ಮರ', 'Book': 'ಪುಸ್ತಕ', 'Chair': 'ಕುರ್ಚಿ', 'Door': 'ದ್ವಾರ', 'House': 'ಮನೆ'
    },
    'te': {
        'Apple': 'ఆపిల్', 'Water': 'నీరు', 'School': 'పాఠశాల', 'Garden': 'తోట', 'Window': 'కిటికీ',
        'Tree': 'చెట్టు', 'Book': 'పుస్తకం', 'Chair': 'కుర్చీ', 'Door': 'ద్వారం', 'House': 'ఇల్లు'
    }
}

OUT = Path('assets') / 'audio'
OUT.mkdir(parents=True, exist_ok=True)

engine = pyttsx3.init()
engine.setProperty('rate', 150)

for lang, mapping in BANKS.items():
    lang_dir = OUT / lang
    lang_dir.mkdir(parents=True, exist_ok=True)
    for label, text in mapping.items():
        filename = lang_dir / f"{label}.wav"
        print(f"Generating {filename} ({lang}): '{text}'")
        engine.save_to_file(text, str(filename))

engine.runAndWait()
print('Done')
