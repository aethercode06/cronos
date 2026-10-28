#!/usr/bin/env python3
"""Aplica la marca Aether Engine al código fuente de Godot antes de compilar
el editor para Android: nombre de la app, identificador del paquete e iconos.
Uso: python3 apply_branding.py <carpeta del código de Godot> <carpeta branding>
"""
import os, re, sys, glob
from PIL import Image

src, brand = sys.argv[1], sys.argv[2]
NAME = "Aether Engine"
APP_ID = "com.aethercode.aetherengine.editor"
changed = []

# 1) nombre visible de la app en todos los idiomas
for f in glob.glob(os.path.join(src, "platform/android/java/editor/src/**/res/values*/strings.xml"), recursive=True):
    t = open(f, encoding="utf-8").read()
    n = re.sub(r"Godot Editor ?4?|Godot Engine ?4?", NAME, t)
    if n != t:
        open(f, "w", encoding="utf-8").write(n); changed.append(f)

# 2) identificador del paquete (se instala aparte del Godot oficial) y nombre de la app
for f in glob.glob(os.path.join(src, "platform/android/java/editor/build.gradle*")):
    t = open(f, encoding="utf-8").read()
    n = re.sub(r'(applicationId\s*=?\s*)"org\.godotengine\.editor\.v4"', r'\1"%s"' % APP_ID, t)
    n = re.sub(r'editorAppName:\s*"[^"]*"', 'editorAppName: "%s"' % NAME, n)
    if n != t:
        open(f, "w", encoding="utf-8").write(n); changed.append(f)

# 3) iconos: cada PNG de icono del editor se sustituye por el de Aether al mismo tamaño
icon = Image.open(os.path.join(brand, "icon_1024.png")).convert("RGBA")
fg = Image.open(os.path.join(brand, "icon_foreground.png")).convert("RGBA")
bg = Image.open(os.path.join(brand, "icon_background.png")).convert("RGBA")
mono = Image.new("RGBA", fg.size, (0, 0, 0, 0))
mono.paste((255, 255, 255, 255), (0, 0), fg.split()[3])
for f in glob.glob(os.path.join(src, "platform/android/java/lib/src/main/res/mipmap*/icon*.webp")) + \
         glob.glob(os.path.join(src, "platform/android/java/lib/src/main/res/mipmap*/icon*.png")):
    base = os.path.basename(f).lower()
    try:
        w, h = Image.open(f).size
    except Exception:
        continue
    pick = mono if "monochrome" in base else fg if "foreground" in base else bg if "background" in base else icon
    pick.resize((w, h), Image.LANCZOS).save(f); changed.append(f)

print("Cambios de marca:")
for c in changed:
    print("  ", os.path.relpath(c, src))
if not changed:
    print("  (ninguno: revisar rutas)")
