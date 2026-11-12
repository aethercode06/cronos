"""Convierte una imagen de cara (1024, encuadre del recorte del concepto) en PNG con alfa para el shader de Godot.
Uso: python cara_png.py <entrada> <salida.png>"""
import sys
from PIL import Image, ImageDraw, ImageFilter
im = Image.open(sys.argv[1]).convert("RGB").resize((1024, 1024), Image.LANCZOS)
# elipse de la cara: centro (0.5, 0.531), semiejes 60/240 y 90/240, borde suave
cx, cy, rx, ry = 512, 0.531 * 1024, 60 / 240 * 1024, 90 / 240 * 1024
m = Image.new("L", (1024, 1024), 0)
d = ImageDraw.Draw(m)
d.ellipse((cx - rx * 0.8, cy - ry * 0.58, cx + rx * 0.8, cy + ry * 0.86), fill=255)  # sin la raya del pelo de la frente
m = m.filter(ImageFilter.GaussianBlur(28))
im.putalpha(m)
im.save(sys.argv[2], optimize=True)
