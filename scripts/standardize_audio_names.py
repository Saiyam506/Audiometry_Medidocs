import os
import shutil
ROOT = os.path.join(os.path.dirname(__file__), '..')
AUDIO_ROOT = os.path.join(ROOT, 'assets', 'audio')
LANGS = ['hi', 'kn', 'te']
BASENAMES = ['apple', 'water', 'school', 'garden',
             'window', 'tree', 'book', 'chair', 'door', 'house']
for lang in LANGS:
    folder = os.path.join(AUDIO_ROOT, lang)
    if not os.path.isdir(folder):
        continue
    for b in BASENAMES:
        src = os.path.join(folder, f"{b}.mp3")
        dst = os.path.join(folder, f"{b.capitalize()}.mp3")
        if os.path.exists(src) and not os.path.exists(dst):
            shutil.copy2(src, dst)
            print('Copied', src, '->', dst)
print('Done')
