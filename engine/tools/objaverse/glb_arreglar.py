"""Arregla un .glb con texturas sin imagen (Blender no pudo guardar alguna): quita las referencias de los
materiales a esas texturas y les pone una imagen válida para que Godot lo importe. Uso: glb_arreglar.py archivo.glb"""
import sys, json, struct
p = sys.argv[1]
b = open(p, 'rb').read()
jl = struct.unpack('<I', b[12:16])[0]
j = json.loads(b[20:20 + jl])
resto = b[20 + jl:]
malas = [i for i, t in enumerate(j.get('textures', [])) if 'source' not in t and not any('source' in e for e in t.get('extensions', {}).values())]
if not malas:
    print('nada que arreglar'); sys.exit()
def limpia(o):
    if isinstance(o, dict):
        for k in list(o.keys()):
            v = o[k]
            if isinstance(v, dict) and 'index' in v and k.endswith('Texture') and v['index'] in malas:
                del o[k]
            else:
                limpia(v)
    elif isinstance(o, list):
        for v in o:
            limpia(v)
limpia(j.get('materials', []))
for i in malas:
    j['textures'][i]['source'] = 0
js = json.dumps(j, separators=(',', ':')).encode()
while len(js) % 4: js += b' '
total = 12 + 8 + len(js) + len(resto)
open(p, 'wb').write(struct.pack('<III', 0x46546C67, 2, total) + struct.pack('<II', len(js), 0x4E4F534A) + js + resto)
print('arreglado', p, malas)
