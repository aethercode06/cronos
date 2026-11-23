"""Vuelve a codificar las imágenes de un .glb como JPEG normal (baseline, 8 bits, RGB) para que Godot las lea.
Uso: python3 glb_jpeg.py entrada.glb salida.glb [calidad] [lado_max]"""
import sys, json, struct, io
from PIL import Image
src, dst = sys.argv[1], sys.argv[2]
q = int(sys.argv[3]) if len(sys.argv) > 3 else 85
lado = int(sys.argv[4]) if len(sys.argv) > 4 else 1024
b = open(src, 'rb').read()
jl = struct.unpack('<I', b[12:16])[0]
j = json.loads(b[20:20 + jl])
binl = struct.unpack('<I', b[20 + jl:24 + jl])[0]
binv = b[28 + jl:28 + jl + binl]
nuevas = {}
for i, im in enumerate(j.get('images', [])):
    bv = j['bufferViews'][im['bufferView']]
    o = bv.get('byteOffset', 0)
    I = Image.open(io.BytesIO(binv[o:o + bv['byteLength']]))
    alfa = I.mode in ('RGBA', 'LA') and I.getchannel('A').getextrema()[0] < 250
    I = I.convert('RGBA' if alfa else 'RGB')
    if max(I.size) > lado:
        I.thumbnail((lado, lado))
    out = io.BytesIO()
    if alfa:
        I.save(out, 'PNG', optimize=True); im['mimeType'] = 'image/png'
    else:
        I.save(out, 'JPEG', quality=q, progressive=False); im['mimeType'] = 'image/jpeg'
    nuevas[im['bufferView']] = out.getvalue()
# reconstruir el buffer binario
nb = bytearray()
for k, bv in enumerate(j['bufferViews']):
    o = bv.get('byteOffset', 0)
    d = nuevas.get(k, binv[o:o + bv['byteLength']])
    while len(nb) % 4: nb.append(0)
    bv['byteOffset'] = len(nb); bv['byteLength'] = len(d)
    nb += d
while len(nb) % 4: nb.append(0)
j['buffers'][0]['byteLength'] = len(nb)
js = json.dumps(j, separators=(',', ':')).encode()
while len(js) % 4: js += b' '
total = 12 + 8 + len(js) + 8 + len(nb)
with open(dst, 'wb') as f:
    f.write(struct.pack('<III', 0x46546C67, 2, total))
    f.write(struct.pack('<II', len(js), 0x4E4F534A)); f.write(js)
    f.write(struct.pack('<II', len(nb), 0x004E4942)); f.write(nb)
print('ok', dst, total)
