# Versión web dividida en archivos de menos de 10 MB (para Vercel/Netlify y PWABuilder).
# Uso: python3 src/build_web.py  -> genera web/
import re, json, os, shutil
B = os.path.dirname(os.path.abspath(__file__)) + '/'
R = os.path.join(B, '..'); OUT = os.path.join(R, 'web'); os.makedirs(OUT, exist_ok=True)
html = open(os.path.join(R, 'www', 'index.html')).read()
head, body = html.split('<body>', 1)
scripts = re.findall(r'<script>\n?(.*?)</script>', body, re.S)
data, game = scripts[0], scripts[1]
# trocear los datos por declaraciones "const IMG..=" para no partir nada a la mitad
parts, cur = [], ''
for chunk in re.split(r'(?=\nconst )', data):
    if len(cur) + len(chunk) > 8_500_000 and cur: parts.append(cur); cur = ''
    cur += chunk
if cur: parts.append(cur)
names = []
for i, p in enumerate(parts):
    n = 'datos%d.js' % (i + 1); open(os.path.join(OUT, n), 'w').write(p); names.append(n)
open(os.path.join(OUT, 'juego.js'), 'w').write(game); names.append('juego.js')
rest = re.sub(r'<script>.*?</script>\n?', '', body, flags=re.S)
tags = ''.join('<script src="%s"></script>\n' % n for n in names)
if len(scripts) > 2: tags += '<script>' + scripts[2] + '</script>\n'
out = head + '<body>' + rest.replace('</body>', tags + '</body>') if '</body>' in rest else head + '<body>' + rest + tags
open(os.path.join(OUT, 'index.html'), 'w').write(out)
for f in ['manifest.webmanifest', 'privacidad.html']: shutil.copy(os.path.join(R, 'www', f), OUT)
shutil.copytree(os.path.join(R, 'www', 'icons'), os.path.join(OUT, 'icons'), dirs_exist_ok=True)
sw = open(os.path.join(R, 'www', 'sw.js')).read()
sw = sw.replace("'./manifest.webmanifest'", "'./manifest.webmanifest', " + ', '.join("'./%s'" % n for n in names))
open(os.path.join(OUT, 'sw.js'), 'w').write(sw)
for f in sorted(os.listdir(OUT)):
    p = os.path.join(OUT, f)
    if os.path.isfile(p): print(f, os.path.getsize(p) // 1024, 'KB')
