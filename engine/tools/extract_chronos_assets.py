"""Saca todo el arte y el sonido de Chronos (src/*assets.js) a engine/assets/chronos.
Respeta el mismo orden de mezcla que el juego web (IMG, IMG2…IMG11, IMG12)."""
import base64, json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, 'src')
OUT = os.path.join(ROOT, 'engine', 'assets', 'chronos')
dec = json.JSONDecoder()

def objects(text):
    out = {}
    for m in re.finditer(r'(?:const|let|var)\s+([A-Z]+\d*)\s*=\s*', text):
        try:
            obj, _ = dec.raw_decode(text, m.end())
            out[m.group(1)] = obj
        except Exception:
            pass
    for m in re.finditer(r'Object\.assign\((MUS|SND),\s*', text):
        try:
            obj, _ = dec.raw_decode(text, m.end())
            out.setdefault(m.group(1), {}).update(obj)
        except Exception:
            pass
    return out

allobj = {}
for f in sorted(os.listdir(SRC)):
    if f.endswith('assets.js'):
        for k, v in objects(open(os.path.join(SRC, f), encoding='utf-8').read()).items():
            allobj.setdefault(k, {}).update(v)

img, meta = {}, {}
for suf in [''] + [str(i) for i in range(2, 13)]:
    img.update(allobj.get('IMG' + suf, {}))
    meta.update(allobj.get('META' + suf, {}))
os.makedirs(OUT, exist_ok=True)
os.makedirs(os.path.join(OUT, 'audio'), exist_ok=True)
n = 0
for k, url in img.items():
    m = re.match(r'data:image/(\w+);base64,(.*)', url, re.S)
    if not m:
        continue
    ext = 'jpg' if m.group(1) == 'jpeg' else m.group(1)
    fn = k + '.' + ext
    open(os.path.join(OUT, fn), 'wb').write(base64.b64decode(m.group(2)))
    meta.setdefault(k, {})['file'] = fn
    n += 1
for group in ('MUS', 'SND'):
    for k, url in allobj.get(group, {}).items():
        m = re.match(r'data:audio/(\w+);base64,(.*)', url, re.S)
        if m:
            ext = 'mp3' if m.group(1) == 'mpeg' else m.group(1)
            open(os.path.join(OUT, 'audio', k + '.' + ext), 'wb').write(base64.b64decode(m.group(2)))
meta = {k: v for k, v in meta.items() if 'file' in v}
json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), ensure_ascii=False)
print('imágenes', n, 'meta', len(meta), 'grupos', list(allobj.keys()))
