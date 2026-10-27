# Construye www/index.html (un solo archivo) a partir de los módulos de src/.
# Uso:  python3 src/build.py
import re, json, os
B = os.path.dirname(os.path.abspath(__file__)) + '/'
OUT = os.path.join(B, '..', 'www', 'index.html')

assets = open(B + 'assets.js').read()
m = re.search(r'const IMG=(\{.*?\});\n', assets, re.S); IMG = json.loads(m.group(1))
for k in list(IMG):
    if k.startswith('H_') or k.startswith('DK_'): del IMG[k]
assets = assets[:m.start()] + 'const IMG=' + json.dumps(IMG) + ';\n' + assets[m.end():]
h8 = open(B + 'hf8assets.js').read(); m8 = re.search(r'const IMG4=(\{.*?\});\n', h8, re.S); I4 = json.loads(m8.group(1))
I5 = json.loads(re.search(r'const IMG5=(\{.*?\});\n', open(B + 'hf9assets.js').read(), re.S).group(1))
for k in I5: I4.pop(k, None)
hf8 = h8[:m8.start()] + 'const IMG4=' + json.dumps(I4) + ';\n' + h8[m8.end():]
fonts = open(B + 'fonts2.js').read()
hf = '\n'.join([open(B + 'hfassets.js').read(), open(B + 'hf7assets.js').read(), hf8] +
               [open(B + f).read() for f in ['hf9assets.js', 'hf10assets.js', 'hf11assets.js', 'hf12assets.js', 'hf14assets.js', 'hf15assets.js', 'hf16assets.js', 'hf17assets.js', 'musassets.js', 'sndassets.js']])
MODS = ['core', 'hdrender', 'gl', 'amb', 'story', 'data', 'logic', 'ext', 'terrain', 'hd', 'live', 'live2', 'render', 'particles', 'abilities', 'flow', 'ui', 'polish', 'modes', 'foes', 'rush', 'music', 'secret', 'tele', 'bestiary', 'bossfix', 'gates', 'pace', 'mix', 'screen', 'hook', 'i18n_data', 'i18n_extra', 'i18n_extra2', 'i18n']
game = '\n'.join(open(B + f + '.js').read() for f in MODS)

head = open(B + 'head.html').read()
head = head.replace("canvas{display:block;margin:0 auto;touch-action:none;background:#14112a;image-rendering:pixelated;image-rendering:crisp-edges}",
                    "canvas{position:absolute;display:block;touch-action:none;image-rendering:pixelated;image-rendering:crisp-edges}#gl{background:#07050f}#c{background:transparent}")
head = head.replace("github.com/google/fonts -->", "github.com/google/fonts (Exo 2, Orbitron - SIL OFL) -->\n<!-- Arte original de personajes, criaturas, jefes, fondos e ilustraciones: generado para Aether Code con Higgsfield -->")
# PWA: instalable desde el navegador y jugable sin conexión
pwa = ('<link rel="manifest" href="manifest.webmanifest">\n<meta name="theme-color" content="#07050f">\n'
       '<meta name="mobile-web-app-capable" content="yes">\n<meta name="apple-mobile-web-app-capable" content="yes">\n'
       '<link rel="icon" href="icons/icon-192.png">\n<link rel="apple-touch-icon" href="icons/icon-192.png">\n')
head = head.replace('</head>', pwa + '</head>') if '</head>' in head else head + pwa
sw = ("<script>if('serviceWorker' in navigator && location.protocol==='https:' && !window.Capacitor && location.hostname!=='localhost')"
      "addEventListener('load',()=>navigator.serviceWorker.register('sw.js').catch(()=>{}));</script>\n")
html = (head + '<body>\n<canvas id="gl"></canvas>\n<canvas id="c"></canvas>\n<script>\n' + assets + '\n' + hf + '\n' + fonts +
        '\n</script>\n<script>\n' + game + '\n</script>\n' + sw + '</body>\n</html>\n')
open(OUT, 'w').write(html)
# Versión de prueba (todos los mundos abiertos, guardado aparte): www/prueba.html y el APK «Chronos PRUEBA»
prueba = html.replace('<body>\n', '<body>\n<script>window.CHRONOS_PRUEBA=1</script>\n', 1).replace('<title>', '<title>PRUEBA · ', 1)
open(OUT.replace('index.html', 'prueba.html'), 'w').write(prueba)
print('www/index.html', len(html) // 1024, 'KB')
