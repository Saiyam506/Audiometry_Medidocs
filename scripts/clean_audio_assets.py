import os
import shutil

ROOT = os.path.join(os.path.dirname(__file__), '..')
AUDIO_ROOT = os.path.join(ROOT, 'assets', 'audio')
LANGS = ['en', 'hi', 'kn', 'te']
KEEP_BASENAMES = {'apple', 'water', 'school', 'garden',
                  'window', 'tree', 'book', 'chair', 'door', 'house'}
KEEP_EXTS = {'.mp3', '.wav'}

moved = []
for lang in LANGS:
    folder = os.path.join(AUDIO_ROOT, lang)
    if not os.path.isdir(folder):
        continue
    extras = os.path.join(folder, 'extras')
    os.makedirs(extras, exist_ok=True)
    for fname in os.listdir(folder):
        fpath = os.path.join(folder, fname)
        if os.path.isdir(fpath):
            continue
        name, ext = os.path.splitext(fname)
        if ext.lower() not in KEEP_EXTS:
            # keep unknown extensions in extras
            target = os.path.join(extras, fname)
            shutil.move(fpath, target)
            moved.append(fpath)
            continue
        base = name.lower()
        if base in KEEP_BASENAMES:
            # keep
            continue
        # allow companion capitalized wavs like Apple.wav
        if base.capitalize() in KEEP_BASENAMES:
            continue
        # move to extras
        target = os.path.join(extras, fname)
        try:
            shutil.move(fpath, target)
            moved.append(fpath)
        except Exception as e:
            print('Failed to move', fpath, e)

print('Moved files:')
for m in moved:
    print(m)
print('Done')
