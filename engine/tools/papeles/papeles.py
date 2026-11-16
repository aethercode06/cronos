"""Papeles pintados victorianos hechos por código (sin descargas): cada sala tiene el suyo.
Uso: python papeles.py <carpeta_salida>. Salen 1024x1024, repetibles, ya envejecidos."""
import sys, os, math, random
from PIL import Image, ImageDraw, ImageFilter, ImageChops
import numpy as np
OUT = sys.argv[1]; os.makedirs(OUT, exist_ok=True)
S = 2048  # se dibuja al doble y se reduce (bordes suaves)

def lienzo(fondo):
    return Image.new("RGB", (S, S), fondo)

def envuelto(d, fn, x, y):
    for ox in (-S, 0, S):
        for oy in (-S, 0, S):
            if -400 < x + ox < S + 400 and -400 < y + oy < S + 400:
                fn(d, x + ox, y + oy)

def ruido(sem, esc, oct=4):
    rng = np.random.default_rng(sem)
    acc = np.zeros((S // 4, S // 4))
    for o in range(oct):
        n = 2 ** o * esc
        g = rng.random((n, n))
        g = np.tile(g, (1, 1))
        im = Image.fromarray((g * 255).astype(np.uint8)).resize((S // 4, S // 4), Image.BICUBIC, reducing_gap=None)
        # repetible: la rejilla aleatoria se repite al ser periódica por construcción del remuestreo envolvente
        arr = np.asarray(im, dtype=float) / 255.0
        acc += arr / (2 ** o)
    acc = (acc - acc.min()) / (np.ptp(acc) + 1e-6)
    return acc

def envejecer(img, sem, manchas=0.35):
    """Amarillea, añade manchas de humedad y suciedad abajo; mantiene la repetición (manchas suaves periódicas)."""
    rng = np.random.default_rng(sem)
    a = np.asarray(img, dtype=float) / 255.0
    h = S
    # manchas periódicas: suma de senos con fases aleatorias (siempre repetible)
    yy, xx = np.mgrid[0:h, 0:h] / h * 2 * math.pi
    m = np.zeros((h, h))
    for _ in range(9):
        fx, fy = rng.integers(1, 5), rng.integers(1, 5)
        m += np.sin(xx * fx + rng.random() * 6.28) * np.sin(yy * fy + rng.random() * 6.28) / (fx + fy)
    m = (m - m.min()) / (np.ptp(m) + 1e-6)
    sucio = np.clip((m - 0.55) * 3.0, 0, 1) * manchas
    tono = np.array([0.82, 0.74, 0.55])
    a = a * (1 - sucio[..., None] * 0.6) + tono * sucio[..., None] * 0.25
    # grano fino
    a *= 0.94 + rng.random((h, h, 1)) * 0.08
    return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8))

def terminar(img, nombre, sem, manchas=0.35):
    img = img.filter(ImageFilter.GaussianBlur(1.2))
    img = envejecer(img, sem, manchas)
    img = img.resize((1024, 1024), Image.LANCZOS)
    img.save(os.path.join(OUT, nombre + ".jpg"), quality=90)
    print("OK", nombre)

def mezcla(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

# ---- motivos ----
def damasco(fondo, tinta, nombre, sem, n=4):
    img = lienzo(fondo); d = ImageDraw.Draw(img)
    p = S // n
    def motivo(d, cx, cy):
        r = p * 0.42
        pts = []
        for k in range(64):
            t = k / 64 * 2 * math.pi
            # silueta de damasco: rombo curvo con lóbulos
            rr = r * (0.55 + 0.25 * math.cos(2 * t) ** 2 + 0.12 * math.cos(6 * t))
            pts.append((cx + math.sin(t) * rr * 0.72, cy - math.cos(t) * rr))
        d.polygon(pts, fill=tinta)
        d.polygon([(cx + (x - cx) * 0.62, cy + (y - cy) * 0.62) for x, y in pts], fill=fondo)
        for s in (-1, 1):
            for k in range(3):
                yy = cy - r * 0.35 + k * r * 0.35
                d.ellipse((cx + s * r * 0.18 - r * 0.09, yy - r * 0.16, cx + s * r * 0.18 + r * 0.09, yy + r * 0.16), fill=tinta)
        d.ellipse((cx - r * 0.1, cy - r * 0.1, cx + r * 0.1, cy + r * 0.1), fill=tinta)
        # hojitas entre motivos
        d.ellipse((cx + p / 2 - r * 0.12, cy + p / 2 - r * 0.25, cx + p / 2 + r * 0.12, cy + p / 2 + r * 0.25), fill=tinta)
    for i in range(n):
        for j in range(n):
            envuelto(d, motivo, i * p + p / 2 + (p / 2 if j % 2 else 0), j * p + p / 2)
    terminar(img, nombre, sem)

def floral(fondo, tallo, flor, nombre, sem, n=6):
    rng = random.Random(sem)
    img = lienzo(fondo); d = ImageDraw.Draw(img)
    p = S // n
    def ramito(d, cx, cy):
        w = p * 0.03
        d.line([(cx, cy + p * 0.25), (cx + p * 0.04, cy - p * 0.05), (cx - p * 0.02, cy - p * 0.2)], fill=tallo, width=int(w))
        for s in (-1, 1):
            d.ellipse((cx + s * p * 0.07 - p * 0.05, cy + p * 0.05 - p * 0.025, cx + s * p * 0.07 + p * 0.05, cy + p * 0.05 + p * 0.025), fill=tallo)
        for fx, fy, fr in ((cx - p * 0.02, cy - p * 0.22, 0.07), (cx + p * 0.1, cy - p * 0.08, 0.05)):
            for k in range(5):
                a = k / 5 * 2 * math.pi
                d.ellipse((fx + math.cos(a) * p * fr * 0.6 - p * fr * 0.45, fy + math.sin(a) * p * fr * 0.6 - p * fr * 0.45,
                           fx + math.cos(a) * p * fr * 0.6 + p * fr * 0.45, fy + math.sin(a) * p * fr * 0.6 + p * fr * 0.45), fill=flor)
            d.ellipse((fx - p * fr * 0.3, fy - p * fr * 0.3, fx + p * fr * 0.3, fy + p * fr * 0.3), fill=mezcla(flor, (230, 200, 120), 0.6))
    for i in range(n):
        for j in range(n):
            envuelto(d, ramito, i * p + p / 2 + (p / 2 if j % 2 else 0), j * p + p / 2)
    terminar(img, nombre, sem)

def rombos(fondo, linea, punto, nombre, sem, n=8):
    img = lienzo(fondo); d = ImageDraw.Draw(img)
    p = S // n
    w = int(p * 0.035)
    for k in range(-n, 2 * n + 1):
        d.line([(k * p, 0), (k * p + S, S)], fill=linea, width=w)
        d.line([(k * p, 0), (k * p - S, S)], fill=linea, width=w)
    for i in range(n + 1):
        for j in range(n + 1):
            for cx, cy in ((i * p, j * p), (i * p + p / 2, j * p + p / 2)):
                d.ellipse((cx - p * 0.07, cy - p * 0.07, cx + p * 0.07, cy + p * 0.07), fill=punto)
    terminar(img, nombre, sem)

def lirios(fondo, raya, tinta, nombre, sem, n=6):
    img = lienzo(fondo); d = ImageDraw.Draw(img)
    p = S // n
    for i in range(n):
        x = i * p
        d.rectangle((x, 0, x + p * 0.06, S), fill=raya)
        d.rectangle((x + p * 0.1, 0, x + p * 0.12, S), fill=raya)
    def lis(d, cx, cy):
        r = p * 0.22
        d.polygon([(cx, cy - r), (cx + r * 0.22, cy - r * 0.2), (cx, cy + r * 0.3), (cx - r * 0.22, cy - r * 0.2)], fill=tinta)
        for s in (-1, 1):
            d.chord((cx + s * r * 0.15 - r * 0.6, cy - r * 0.7, cx + s * r * 0.15 + r * 0.6, cy + r * 0.3), 90 - s * 90 + (0 if s > 0 else 0), 270 - s * 90, fill=tinta)
            d.ellipse((cx + s * r * 0.55 - r * 0.15, cy - r * 0.35 - r * 0.15, cx + s * r * 0.55 + r * 0.15, cy - r * 0.35 + r * 0.15), fill=fondo)
        d.rectangle((cx - r * 0.45, cy + r * 0.05, cx + r * 0.45, cy + r * 0.17), fill=tinta)
        d.polygon([(cx - r * 0.12, cy + r * 0.17), (cx + r * 0.12, cy + r * 0.17), (cx, cy + r * 0.6)], fill=tinta)
    for i in range(n):
        for j in range(n):
            envuelto(d, lis, i * p + p * 0.58, j * p + p / 2 + (p / 2 if i % 2 else 0))
    terminar(img, nombre, sem)

def enredadera(fondo, tallo, hoja, nombre, sem, n=3):
    img = lienzo(fondo); d = ImageDraw.Draw(img)
    p = S // n
    rng = random.Random(sem)
    for i in range(n):
        x0 = i * p + p / 2
        pts = [(x0 + math.sin(y / S * 2 * math.pi * 3) * p * 0.22, y) for y in range(-20, S + 21, 8)]
        for ox in (-S, 0, S):
            d.line([(x + ox, y) for x, y in pts], fill=tallo, width=int(p * 0.02))
        for y in range(0, S, int(p * 0.18)):
            x = x0 + math.sin(y / S * 2 * math.pi * 3) * p * 0.22
            s = 1 if (y // int(p * 0.18)) % 2 else -1
            def hj(d, cx, cy, s=s):
                L = p * 0.16
                pts = [(cx + s * L * t, cy - math.sin(t * math.pi) * L * 0.35 - t * L * 0.2) for t in np.linspace(0, 1, 12)]
                pts += [(cx + s * L * t, cy + math.sin(t * math.pi) * L * 0.25 - t * L * 0.2) for t in np.linspace(1, 0, 12)]
                d.polygon(pts, fill=hoja)
            envuelto(d, hj, x, y)
            if rng.random() < 0.3:
                envuelto(d, lambda d, cx, cy: d.ellipse((cx - p * 0.03, cy - p * 0.03, cx + p * 0.03, cy + p * 0.03), fill=(150, 40, 45)), x - s * p * 0.05, y + p * 0.05)
    terminar(img, nombre, sem)

def estrellas(fondo, raya, estrella, nombre, sem, n=8):
    img = lienzo(fondo); d = ImageDraw.Draw(img)
    p = S // n
    for i in range(n):
        d.rectangle((i * p, 0, i * p + p * 0.5, S), fill=raya)
    def est(d, cx, cy):
        r = p * 0.14
        pts = []
        for k in range(10):
            a = k / 10 * 2 * math.pi - math.pi / 2
            rr = r if k % 2 == 0 else r * 0.45
            pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
        d.polygon(pts, fill=estrella)
    for i in range(n):
        for j in range(n):
            envuelto(d, est, i * p + p * 0.75, j * p + p / 2 + (p / 2 if i % 2 else 0))
    terminar(img, nombre, sem, 0.5)

def tartan(fondo, a, b, nombre, sem, n=4):
    img = lienzo(fondo).convert("RGBA"); p = S // n
    capa = Image.new("RGBA", (S, S), (0, 0, 0, 0)); d = ImageDraw.Draw(capa)
    for i in range(n):
        for off, w, c in ((0, 0.28, a), (0.42, 0.06, b), (0.6, 0.12, a), (0.82, 0.02, b)):
            d.rectangle((i * p + off * p, 0, i * p + (off + w) * p, S), fill=c + (110,))
            d.rectangle((0, i * p + off * p, S, i * p + (off + w) * p), fill=c + (110,))
    img = Image.alpha_composite(img, capa).convert("RGB")
    terminar(img, nombre, sem)

def medallones(fondo, tinta, nombre, sem, n=4):
    img = lienzo(fondo); d = ImageDraw.Draw(img)
    p = S // n
    def med(d, cx, cy):
        r = p * 0.3
        d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=tinta, width=int(p * 0.025))
        d.ellipse((cx - r * 0.82, cy - r * 0.82, cx + r * 0.82, cy + r * 0.82), outline=tinta, width=int(p * 0.01))
        for k in range(8):
            a = k / 8 * 2 * math.pi
            x, y = cx + math.cos(a) * r * 0.45, cy + math.sin(a) * r * 0.45
            d.ellipse((x - r * 0.18, y - r * 0.18, x + r * 0.18, y + r * 0.18), fill=tinta)
        d.ellipse((cx - r * 0.2, cy - r * 0.2, cx + r * 0.2, cy + r * 0.2), fill=fondo, outline=tinta, width=int(p * 0.015))
        for k in range(4):
            a = k / 4 * 2 * math.pi + math.pi / 4
            x, y = cx + math.cos(a) * p * 0.5, cy + math.sin(a) * p * 0.5
            d.ellipse((x - p * 0.05, y - p * 0.05, x + p * 0.05, y + p * 0.05), fill=tinta)
    for i in range(n):
        for j in range(n):
            envuelto(d, med, i * p + p / 2, j * p + p / 2)
    terminar(img, nombre, sem)

def escamas(fondo, tinta, nombre, sem, n=10):
    img = lienzo(fondo); d = ImageDraw.Draw(img); p = S // n
    for j in range(n + 1):
        for i in range(n + 1):
            cx = i * p + (p / 2 if j % 2 else 0); cy = j * p * 0.6
            envuelto(d, lambda d, x, y: d.arc((x - p / 2, y - p / 2, x + p / 2, y + p / 2), 0, 180, fill=tinta, width=int(p * 0.05)), cx, cy)
    # la altura de la rejilla debe repetirse: S debe ser múltiplo de 0.6p*2 → se corrige reescalando verticalmente
    terminar(img, nombre, sem)

damasco((92, 28, 30), (128, 52, 48), "damasco_rojo", 1)          # salón de baile / epicentro
damasco((40, 52, 40), (66, 82, 58), "damasco_verde", 2)          # biblioteca
damasco((175, 160, 130), (150, 128, 92), "damasco_crema", 3)     # galería de retratos
floral((198, 182, 170), (92, 110, 80), (170, 90, 100), "floral_rosa", 4)    # tocador de la madre
floral((60, 70, 92), (120, 130, 110), (200, 180, 140), "floral_azul", 5)    # huéspedes / dormitorio padres
rombos((120, 110, 80), (80, 70, 50), (160, 140, 90), "rombos_ocre", 6)      # comedor
lirios((48, 58, 82), (58, 70, 96), (160, 135, 80), "lirios_azul", 7)        # dormitorio de los padres
enredadera((170, 162, 132), (90, 100, 72), (76, 98, 66), "enredadera", 8)  # sala de música / costura
estrellas((190, 178, 150), (175, 190, 196), (210, 170, 90), "estrellas_ninos", 9)  # cuarto de niños
tartan((40, 52, 44), (80, 30, 30), (170, 150, 90), "tartan", 10)           # estudio del padre / fumar
medallones((160, 140, 100), (120, 96, 58), "medallones_oro", 11)            # vestíbulo
floral((150, 150, 120), (70, 80, 60), (120, 60, 70), "floral_palido", 12)   # institutriz / hermano
