"""Planos de la Mansión Varela con estilo de arquitecto (a partir de plano.py).
Uso: python3 arquitecto.py <carpeta_salida>"""
import sys, os, math, random, importlib.util
from PIL import Image, ImageDraw, ImageFont

OUT = sys.argv[1] if len(sys.argv) > 1 else "."
spec = importlib.util.spec_from_file_location("plano", os.path.join(os.path.dirname(__file__), "plano.py"))
sys.argv = [sys.argv[0], OUT]
plano = importlib.util.module_from_spec(spec); spec.loader.exec_module(plano)
P = plano.PLANTAS

PAPER = (246, 243, 234)
INK = (28, 28, 30)
FAINT = (205, 200, 188)
RED = (176, 32, 36)
BLUE = (70, 110, 150)
F = "/usr/share/fonts/truetype/dejavu/"
def fnt(sz, bold=False, serif=False):
    n = ("DejaVuSerif-Bold.ttf" if bold else "DejaVuSerif.ttf") if serif else ("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf")
    return ImageFont.truetype(F + n, sz)

def hatch(d, box, step=7, col=INK, w=1):
    x0, y0, x1, y1 = box
    for k in range(int(x0 - (y1 - y0)), int(x1), step):
        a = (max(x0, k), y0 + max(0, x0 - k))
        b = (min(x1, k + (y1 - y0)), y0 + min(y1 - y0, x1 - k))
        if a[0] < b[0]:
            d.line([a, b], fill=col, width=w)

def frame(im, title, sub, plate):
    d = ImageDraw.Draw(im)
    W, H = im.size
    d.rectangle([14, 14, W - 15, H - 15], outline=INK, width=3)
    d.rectangle([22, 22, W - 23, H - 23], outline=INK, width=1)
    # cajetín
    bx0, by0 = W - 520, H - 170
    d.rectangle([bx0, by0, W - 23, H - 23], outline=INK, width=2)
    d.line([bx0, by0 + 46, W - 23, by0 + 46], fill=INK, width=1)
    d.line([bx0, by0 + 92, W - 23, by0 + 92], fill=INK, width=1)
    d.text((bx0 + 14, by0 + 10), "MANSIÓN VARELA · 1874", fill=INK, font=fnt(22, True, True))
    d.text((bx0 + 14, by0 + 56), title, fill=INK, font=fnt(20, True))
    d.text((bx0 + 14, by0 + 100), sub, fill=INK, font=fnt(14))
    d.text((W - 120, by0 + 100), f"Lámina {plate}", fill=INK, font=fnt(14))
    d.text((bx0 + 14, by0 + 118), "Aether Code · La Sombra de Zarek", fill=(90, 90, 90), font=fnt(13))

def north(d, x, y):
    d.polygon([(x, y - 34), (x - 13, y + 14), (x, y + 4)], fill=INK)
    d.polygon([(x, y - 34), (x + 13, y + 14), (x, y + 4)], outline=INK, fill=PAPER)
    d.ellipse([x - 24, y - 24, x + 24, y + 24], outline=INK, width=2)
    d.text((x - 6, y - 64), "N", fill=INK, font=fnt(22, True, True))

def scalebar(d, x, y, ppm, meters=15):
    seg = meters / 3
    for i in range(3):
        d.rectangle([x + i * seg * ppm, y, x + (i + 1) * seg * ppm, y + 8], fill=INK if i % 2 == 0 else PAPER, outline=INK)
        d.text((x + i * seg * ppm - 4, y + 12), str(int(i * seg)), fill=INK, font=fnt(13))
    d.text((x + 3 * seg * ppm - 8, y + 12), f"{meters} m", fill=INK, font=fnt(13))

def dim(d, a, b, txt, vertical=False):
    d.line([a, b], fill=INK, width=1)
    for p in (a, b):
        d.line([(p[0] - 6, p[1] + 6), (p[0] + 6, p[1] - 6)], fill=INK, width=2)
    mx, my = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
    f = fnt(15)
    tw = d.textlength(txt, font=f)
    if vertical:
        t = Image.new("RGBA", (int(tw) + 8, 22), (0, 0, 0, 0))
        ImageDraw.Draw(t).text((4, 2), txt, fill=INK, font=f)
        t = t.rotate(90, expand=True)
        return t, (int(mx - 24), int(my - t.size[1] / 2))
    d.text((mx - tw / 2, my - 22), txt, fill=INK, font=f)
    return None, None

def floor_plan(key, plate):
    p = P[key]
    C = 40  # px por celda (3 m)
    ppm = C / 3.0
    zones = [z for z in p["zonas"]]
    W = p["w"] * C + 260
    H = p["h"] * C + 360
    im = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(im)
    ox, oy = 120, 150
    d.text((50, 46), p["titulo"].title() if key != "sotano" else "Sótano y túneles", fill=INK, font=fnt(34, True, True))
    d.text((52, 92), "Planta arquitectónica · escala gráfica · cotas en metros", fill=(80, 80, 80), font=fnt(15))
    # rejilla tenue
    for x in range(p["w"] + 1):
        d.line([(ox + x * C, oy), (ox + x * C, oy + p["h"] * C)], fill=(236, 232, 222))
    for y in range(p["h"] + 1):
        d.line([(ox, oy + y * C), (ox + p["w"] * C, oy + y * C)], fill=(236, 232, 222))
    # suelos
    for (n, t, x, y, w, h) in zones:
        r = [ox + x * C, oy + y * C, ox + (x + w) * C, oy + (y + h) * C]
        fill = (255, 253, 247)
        if t in ("tunel",):
            fill = (232, 230, 226)
        if t == "roca":
            fill = (236, 222, 218)
        if t == "agua":
            fill = (222, 232, 240)
        if t == "jardin":
            fill = (232, 240, 226)
        d.rectangle(r, fill=fill)
        if t == "epicentro":
            hatch(d, r, step=14, col=(232, 205, 205))
        if t == "roca":
            hatch(d, r, step=10, col=(220, 180, 180))
        if t in ("servicio", "pasillo"):
            # baldosas
            for i in range(x, x + w):
                for j in range(y, y + h):
                    d.rectangle([ox + i * C + C / 2 - 1, oy + j * C + C / 2 - 1, ox + i * C + C / 2 + 1, oy + j * C + C / 2 + 1], fill=FAINT)
    # muros (gruesos y rellenos)
    WT = 9
    xs = [z[2] for z in zones] + [z[2] + z[4] for z in zones]
    ys = [z[3] for z in zones] + [z[3] + z[5] for z in zones]
    gx0, gx1, gy0, gy1 = min(xs), max(xs), min(ys), max(ys)
    for (n, t, x, y, w, h) in zones:
        r = [ox + x * C, oy + y * C, ox + (x + w) * C, oy + (y + h) * C]
        wt = WT
        if t == "tunel":
            wt = 6
        for seg in ([r[0], r[1], r[2], r[1]], [r[0], r[3], r[2], r[3]], [r[0], r[1], r[0], r[3]], [r[2], r[1], r[2], r[3]]):
            if seg[0] == seg[2]:
                box = [seg[0] - wt / 2, seg[1] - wt / 2, seg[0] + wt / 2, seg[3] + wt / 2]
            else:
                box = [seg[0] - wt / 2, seg[1] - wt / 2, seg[2] + wt / 2, seg[1] + wt / 2]
            d.rectangle(box, fill=INK)
    # puertas: hueco + hoja + arco
    for (k, x, y) in p.get("puertas", []):
        if k == "h":
            a = (ox + x * C + C * 0.18, oy + y * C)
            b = (ox + x * C + C * 0.82, oy + y * C)
            d.rectangle([a[0], a[1] - WT, b[0], b[1] + WT], fill=(255, 253, 247))
            L = b[0] - a[0]
            d.line([a, (a[0], a[1] - L)], fill=INK, width=3)
            d.arc([a[0] - L, a[1] - L, a[0] + L, a[1] + L], 270, 360, fill=INK, width=1)
        else:
            a = (ox + x * C, oy + y * C + C * 0.18)
            b = (ox + x * C, oy + y * C + C * 0.82)
            d.rectangle([a[0] - WT, a[1], b[0] + WT, b[1]], fill=(255, 253, 247))
            L = b[1] - a[1]
            d.line([a, (a[0] + L, a[1])], fill=INK, width=3)
            d.arc([a[0] - L, a[1] - L, a[0] + L, a[1] + L], 0, 90, fill=INK, width=1)
    # ventanas en el muro exterior (no en sótano)
    if key in ("baja", "alta", "atico"):
        doors = set((k, x, y) for (k, x, y) in p.get("puertas", []))
        for (n, t, x, y, w, h) in zones:
            for i in range(x, x + w):
                for (yy, side) in ((y, "top"), (y + h, "bot")):
                    if yy in (gy0, gy1) and i % 2 == 1 and ("h", i, yy) not in doors:
                        cx0, cx1, cy = ox + i * C + 6, ox + (i + 1) * C - 6, oy + yy * C
                        d.rectangle([cx0, cy - WT / 2, cx1, cy + WT / 2], fill=PAPER, outline=INK)
                        d.line([cx0, cy, cx1, cy], fill=INK, width=1)
            for j in range(y, y + h):
                for xx in (x, x + w):
                    if xx in (gx0, gx1) and j % 2 == 1 and ("v", xx, j) not in doors:
                        cy0, cy1, cx = oy + j * C + 6, oy + (j + 1) * C - 6, ox + xx * C
                        d.rectangle([cx - WT / 2, cy0, cx + WT / 2, cy1], fill=PAPER, outline=INK)
                        d.line([cx, cy0, cx, cy1], fill=INK, width=1)
    # elementos: escaleras, chimeneas, muebles del juego
    for (k, x, y, txt) in p.get("marcas", []):
        px, py = ox + x * C, oy + y * C
        if k == "escalera":
            bw, bh = C * 1.3, C * 1.9
            r = [px - bw / 2, py - bh / 2, px + bw / 2, py + bh / 2]
            d.rectangle(r, outline=INK, width=2)
            for i in range(1, 11):
                yy = r[1] + i * bh / 11
                d.line([r[0], yy, r[2], yy], fill=INK, width=1)
            d.line([px, r[3] - 4, px, r[1] + 8], fill=INK, width=2)
            d.polygon([(px - 6, r[1] + 14), (px + 6, r[1] + 14), (px, r[1] + 4)], fill=INK)
            if txt:
                d.text((r[2] + 6, py - 9), txt, fill=INK, font=fnt(13))
        elif k == "chimenea":
            r = [px - C * 0.55, py - C * 0.25, px + C * 0.55, py + C * 0.25]
            d.rectangle(r, fill=PAPER, outline=INK, width=2)
            hatch(d, r, step=5)
        elif k == "armario":
            r = [px - C * 0.45, py - C * 0.28, px + C * 0.45, py + C * 0.28]
            d.rectangle(r, fill=PAPER, outline=INK, width=2)
            d.line([r[0], r[1], r[2], r[3]], fill=INK)
            d.line([r[0], r[3], r[2], r[1]], fill=INK)
        elif k == "piano":
            d.rounded_rectangle([px - C * 0.7, py - C * 0.5, px + C * 0.7, py + C * 0.5], radius=14, outline=INK, width=2)
        elif k == "circulo":
            d.ellipse([px - C * 1.5, py - C * 1.5, px + C * 1.5, py + C * 1.5], outline=RED, width=3)
            d.regular_polygon((px, py, C * 1.25), 5, outline=RED)
        elif k == "sello":
            d.regular_polygon((px, py, 11), 5, fill=(214, 160, 40), outline=INK)
            d.text((px + 14, py - 9), txt, fill=(150, 100, 0), font=fnt(13, True))
        elif k == "lampara":
            d.ellipse([px - 7, py - 7, px + 7, py + 7], outline=INK, width=2)
            d.line([px - 10, py - 10, px + 10, py + 10], fill=INK)
            d.line([px - 10, py + 10, px + 10, py - 10], fill=INK)
        elif k == "pasadizo":
            d.line([px - 18, py, px + 18, py], fill=(120, 60, 170), width=3)
            d.text((px + 20, py - 9), txt, fill=(120, 60, 170), font=fnt(13, True))
        elif k == "tunel":
            pass
        else:
            d.ellipse([px - 5, py - 5, px + 5, py + 5], fill=INK)
            if txt:
                d.text((px + 9, py - 9), txt, fill=(60, 60, 60), font=fnt(12))
    # nombres y superficies
    for (n, t, x, y, w, h) in zones:
        cx, cy = ox + (x + w / 2) * C, oy + (y + h / 2) * C
        name = n.upper()
        fs = 15 if w >= 5 else 12
        lines, cur = [], ""
        for word in name.split(" "):
            if d.textlength((cur + " " + word).strip(), font=fnt(fs, True)) > w * C - 14 and cur:
                lines.append(cur); cur = word
            else:
                cur = (cur + " " + word).strip()
        lines.append(cur)
        area = f"{w * h * 9} m²"
        total_h = len(lines) * (fs + 3) + 18
        ty = cy - total_h / 2
        if h >= 4:
            ty = oy + y * C + 16
        for ln in lines:
            tw = d.textlength(ln, font=fnt(fs, True))
            d.text((cx - tw / 2, ty), ln, fill=INK, font=fnt(fs, True))
            ty += fs + 3
        tw = d.textlength(area, font=fnt(12))
        d.text((cx - tw / 2, ty + 2), area, fill=(110, 110, 110), font=fnt(12))
    # cotas generales
    X0, X1 = ox + gx0 * C, ox + gx1 * C
    Y0, Y1 = oy + gy0 * C, oy + gy1 * C
    for xx in (X0, X1):
        d.line([xx, Y0 - 12, xx, Y0 - 60], fill=INK)
    dim(d, (X0, Y0 - 44), (X1, Y0 - 44), f"{(gx1 - gx0) * 3} m")
    for yy in (Y0, Y1):
        d.line([X0 - 12, yy, X0 - 70, yy], fill=INK)
    d.line([X0 - 52, Y0, X0 - 52, Y1], fill=INK)
    for yy in (Y0, Y1):
        d.line([X0 - 58, yy + 6, X0 - 46, yy - 6], fill=INK, width=2)
    t = Image.new("RGBA", (120, 24), (0, 0, 0, 0))
    ImageDraw.Draw(t).text((4, 2), f"{(gy1 - gy0) * 3} m", fill=INK, font=fnt(15))
    t = t.rotate(90, expand=True)
    im.paste(t, (int(X0 - 82), int((Y0 + Y1) / 2 - 60)), t)
    north(d, W - 90, 110)
    scalebar(d, 60, H - 70, ppm)
    frame(im, {"baja": "Planta baja", "alta": "Primer piso", "atico": "Ático y mirador", "sotano": "Sótano y túneles"}[key],
          "Superficie construida: %d m²" % sum(z[4] * z[5] * 9 for z in zones if z[1] not in ("jardin",)), plate)
    return im

def site_plan(plate):
    p = P["exterior"]
    C = 15
    W, H = p["w"] * C + 220, p["h"] * C + 320
    im = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(im)
    ox, oy = 100, 150
    d.text((50, 46), "Plano de situación", fill=INK, font=fnt(34, True, True))
    d.text((52, 92), "La mansión y sus terrenos en medio del bosque · escala gráfica", fill=(80, 80, 80), font=fnt(15))
    rnd = random.Random(7)
    zones = p["zonas"]
    def inside(px, py, names):
        for (n, t, x, y, w, h) in zones:
            if n in names and ox + x * C <= px <= ox + (x + w) * C and oy + y * C <= py <= oy + (y + h) * C:
                return True
        return False
    # árboles (símbolo de copa) fuera de los terrenos
    for i in range(2600):
        tx, ty = ox + rnd.uniform(0, p["w"] * C), oy + rnd.uniform(0, p["h"] * C)
        if inside(tx, ty, ("Terrenos de la mansión (jardines salvajes, muro de piedra)", "Camino del bosque", "Sendero", "Arroyo",
                           "Cabaña del cazador", "Claro del columpio", "Árbol de los cuervos", "Puente viejo")):
            continue
        r = rnd.uniform(9, 17)
        d.ellipse([tx - r, ty - r, tx + r, ty + r], outline=(80, 110, 80), fill=(236, 240, 228), width=1)
        d.ellipse([tx - 1.5, ty - 1.5, tx + 1.5, ty + 1.5], fill=(80, 110, 80))
    for (n, t, x, y, w, h) in zones:
        r = [ox + x * C, oy + y * C, ox + (x + w) * C, oy + (y + h) * C]
        if t == "bosque" and n.startswith("Bosque"):
            continue
        if n.startswith("Terrenos"):
            d.rectangle(r, fill=(240, 244, 232))
            d.rectangle(r, outline=INK, width=5)
            for k in range(int(r[0]), int(r[2]), 14):
                d.line([k, r[1] - 4, k, r[1] + 4], fill=INK)
                d.line([k, r[3] - 4, k, r[3] + 4], fill=INK)
            continue
        if t == "jardin":
            continue
        if n == "Laberinto de setos":
            d.rectangle(r, fill=(216, 230, 208), outline=(60, 90, 60), width=2)
            for k in range(3):
                d.rectangle([r[0] + 12 + k * 14, r[1] + 12 + k * 14, r[2] - 12 - k * 14, r[3] - 12 - k * 14], outline=(60, 90, 60), width=3)
            continue
        if t == "edificio":
            d.rectangle(r, fill=(200, 196, 188), outline=INK, width=3)
            hatch(d, r, step=8, col=(120, 116, 110))
            continue
        if t == "agua":
            d.rectangle(r, fill=(214, 228, 240), outline=BLUE, width=2)
            for k in range(int(r[1]) + 6, int(r[3]), 8):
                d.arc([r[0] + 6, k - 4, r[0] + 26, k + 4], 0, 180, fill=BLUE)
            continue
        if t == "camino":
            d.rectangle(r, fill=(226, 216, 196))
    # caminos con borde
    for (n, t, x, y, w, h) in zones:
        if t == "camino":
            r = [ox + x * C, oy + y * C, ox + (x + w) * C, oy + (y + h) * C]
            d.rectangle(r, outline=(140, 120, 90), width=1)
    for (n, t, x, y, w, h) in zones:
        if n.startswith("Bosque") or n in ("Camino del bosque", "Sendero", "Arroyo", "Camino de entrada"):
            continue
        cx, cy = ox + (x + w / 2) * C, oy + (y + h / 2) * C
        fs = 22 if n.startswith("MANSIÓN") else 13
        if n.startswith("Terrenos"):
            cy = oy + y * C + 16
            fs = 14
        txt = n.upper()
        tw = d.textlength(txt, font=fnt(fs, True))
        if tw > w * C + 40 and not n.startswith("Terrenos"):
            parts = txt.split(" ")
            half = len(parts) // 2
            for i, ln in enumerate([" ".join(parts[:half]), " ".join(parts[half:])]):
                tw = d.textlength(ln, font=fnt(fs, True))
                d.text((cx - tw / 2, cy - fs + i * (fs + 2)), ln, fill=INK, font=fnt(fs, True))
        else:
            d.rectangle([cx - tw / 2 - 3, cy - fs / 2 - 2, cx + tw / 2 + 3, cy + fs / 2 + 4], fill=PAPER)
            d.text((cx - tw / 2, cy - fs / 2), txt, fill=INK, font=fnt(fs, True))
    for (k, x, y, txt) in p["marcas"]:
        px, py = ox + x * C, oy + y * C
        if k == "inicio":
            d.polygon([(px - 10, py + 8), (px + 10, py + 8), (px, py - 12)], fill=(40, 140, 70))
            d.text((px + 14, py - 8), txt, fill=(30, 110, 50), font=fnt(13, True))
        elif k == "sello":
            d.regular_polygon((px, py, 10), 5, fill=(214, 160, 40), outline=INK)
        elif k == "susto":
            d.ellipse([px - 6, py - 6, px + 6, py + 6], fill=RED)
            if txt:
                d.text((px + 10, py - 8), txt, fill=RED, font=fnt(12, True))
        elif k == "puerta":
            d.ellipse([px - 5, py - 5, px + 5, py + 5], fill=INK)
    north(d, W - 80, 110)
    scalebar(d, 60, H - 70, C / 3.0, 60)
    frame(im, "Plano de situación", "Terreno: %d × %d m · finca amurallada" % (p["w"] * 3, p["h"] * 3), plate)
    return im

imgs = [site_plan(1)] + [floor_plan(k, i + 2) for i, k in enumerate(["baja", "alta", "atico", "sotano"])]
names = ["situacion", "planta_baja", "primer_piso", "atico", "sotano"]
for im, n in zip(imgs, names):
    im.save(os.path.join(OUT, f"arq_{n}.png"))
print("ARQ OK", [im.size for im in imgs])
