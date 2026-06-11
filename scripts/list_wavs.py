import os
from glob import glob
wav_files = glob('assets/audio/**/*.wav', recursive=True)
wav_files = sorted(set(wav_files))
print('Found', len(wav_files), 'wav files; sample sizes:')
for p in wav_files[:30]:
    try:
        s = os.path.getsize(p)
    except:
        s = 0
    print(p, s)
