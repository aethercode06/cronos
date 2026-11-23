"""Texturas de terror para la Mansión Varela (calcomanías RGBA): escritos en la pared, arañazos,
huellas de manos, círculos de sal, símbolos del ritual, dibujos infantiles, retratos rayados,
grietas de espejo, manchas de humedad. Todo dibujado por código (sin material de terceros)."""
import math, random, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops
import numpy as np

OUT = sys.argv[1] if len(sys.argv) > 1 else "terror"
FUENTE = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FUENTE2 = "/usr/share/fonts/truetype/dejavu/DejaVuSerifCondensed-BoldItalic.ttf"

def ruido(w, h, escala, sem):
    rng = np.random.default_rng(sem)
    acc = np.zeros((h, w), np.float32)
    amp = 1.0
    s = escala
    while s >= 2:
        g = rng.random((max(2, h // s + 2), max(2, w // s + 2))).astype(np.float32)
        im = Image.fromarray((g * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
        acc += np.asarray(im, np.float32) / 255.0 * amp
        amp *= 0.5
        s //= 2
    acc -= acc.min(); acc /= max(1e-6, acc.max())
    return acc

def guardar(nombre, rgb, alfa):
    a = np.clip(alfa, 0, 1)
    im = np.dstack([np.clip(rgb, 0, 255).astype(np.uint8), (a * 255).astype(np.uint8)])
    Image.fromarray(im, "RGBA").save(f"{OUT}/{nombre}.png", optimize=True)

def color_img(w, h, c, var, sem):
    n = ruido(w, h, 64, sem)[..., None]
    base = np.array(c, np.float32)[None, None, :]
    return base * (1.0 - var + 2 * var * n)

# ---------- escritos a mano en la pared ----------
def escrito(nombre, texto, c=(70, 12, 10), w=1024, h=512, sem=1, goteo=True, tam=None, fuente=FUENTE):
    rnd = random.Random(sem)
    m = Image.new("L", (w, h), 0)
    lineas = texto.split("\n")
    tam = tam or int(h / (len(lineas) * 1.35))
    while max(ImageFont.truetype(fuente, tam).getlength(l) for l in lineas) * 1.12 > w * 0.86:
        tam -= 2
    f = ImageFont.truetype(fuente, tam)
    y = (h - len(lineas) * tam * 1.25) / 2
    for li in lineas:
        x = (w - f.getlength(li) * 1.08) / 2 + rnd.uniform(-20, 20)
        for ch in li:
            if ch == " ":
                x += tam * 0.45; continue
            t = int(tam * rnd.uniform(0.85, 1.15))
            capa = Image.new("L", (t * 2, t * 2), 0)
            ImageDraw.Draw(capa).text((t * 0.5, t * 0.3), ch, 255, font=ImageFont.truetype(fuente, t))
            capa = capa.rotate(rnd.uniform(-14, 14), Image.BICUBIC)
            m.paste(255, (int(x - t * 0.5), int(y + rnd.uniform(-10, 10) - t * 0.3)), capa)
            x += ImageFont.truetype(fuente, t).getlength(ch) * rnd.uniform(1.0, 1.1) + 4
        y += tam * 1.25
    a = np.asarray(m, np.float32) / 255.0
    # trazo de dedo: bordes deshilachados y pintura irregular
    n = ruido(w, h, 16, sem + 3)
    # pintura con los dedos: más carga al principio de cada trazo, rayas verticales de los dedos
    rayas = np.asarray(Image.fromarray((np.random.default_rng(sem).random((1, w)) * 255).astype(np.uint8)).resize((w, h), Image.NEAREST), np.float32) / 255
    a = np.clip(a * (0.75 + 0.35 * n) * (0.8 + 0.25 * rayas) - 0.25 * (n < 0.25), 0, 1)
    if goteo:
        rng = np.random.default_rng(sem)
        col = a.max(axis=0)
        for _ in range(int(w * 0.05)):
            x = int(rng.integers(0, w))
            if col[x] < 0.5:
                continue
            ys = np.nonzero(a[:, x] > 0.5)[0]
            y0 = int(ys.max()); largo = int(rng.integers(10, h // 3)); g = int(rng.integers(2, 5))
            for yy in range(y0, min(h - 1, y0 + largo)):
                k = 1.0 - (yy - y0) / largo
                a[yy, max(0, x - g):x + g] = np.maximum(a[yy, max(0, x - g):x + g], 0.85 * k)
    a = np.asarray(Image.fromarray((a * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2)), np.float32) / 255
    guardar(nombre, color_img(w, h, c, 0.35, sem), a * 0.92)

# ---------- palotes contando los días ----------
def palotes(nombre, sem=5, w=1024, h=512):
    rnd = random.Random(sem)
    m = Image.new("L", (w, h), 0); d = ImageDraw.Draw(m)
    x = 40; y = 60
    grupos = 0
    while y < h - 140:
        for i in range(4):
            xx = x + i * 26 + rnd.uniform(-4, 4)
            d.line([(xx, y + rnd.uniform(-6, 6)), (xx + rnd.uniform(-8, 8), y + 110 + rnd.uniform(-8, 8))], 255, rnd.randint(5, 8))
        d.line([(x - 12, y + 85), (x + 100, y + 20)], 255, 6)
        grupos += 1
        x += 150
        if x > w - 150:
            x = 40 + rnd.uniform(0, 30); y += 150
    a = np.asarray(m.filter(ImageFilter.GaussianBlur(1.0)), np.float32) / 255 * (0.6 + 0.4 * ruido(w, h, 16, sem))
    guardar(nombre, color_img(w, h, (35, 30, 28), 0.3, sem), a)

# ---------- arañazos de uñas ----------
def aranazos(nombre, sem=7, w=512, h=1024, grupos=3):
    rng = np.random.default_rng(sem)
    rgb = np.zeros((h, w, 3), np.float32); a = np.zeros((h, w), np.float32)
    yy, xx = np.mgrid[0:h, 0:w]
    for g in range(grupos):
        cx = rng.uniform(w * 0.2, w * 0.8); y0 = rng.uniform(0, h * 0.3); y1 = rng.uniform(h * 0.6, h)
        curva = rng.uniform(-60, 60)
        for dedo in range(4):
            off = (dedo - 1.5) * rng.uniform(22, 32)
            t = np.clip((yy - y0) / (y1 - y0), 0, 1)
            xc = cx + off + curva * t * t
            prof = np.where((yy > y0) & (yy < y1), np.sin(t * math.pi) ** 0.5, 0)
            dist = np.abs(xx - xc)
            surco = np.clip(1 - dist / 4.0, 0, 1) * prof
            borde = np.clip(1 - np.abs(dist - 5) / 2.5, 0, 1) * prof * 0.6
            a = np.maximum(a, np.maximum(surco, borde))
            rgb = np.where((surco > 0.05)[..., None], np.array([30, 22, 18], np.float32), np.where((borde > 0.05)[..., None], np.array([200, 185, 160], np.float32), rgb))
    a *= 0.55 + 0.45 * ruido(w, h, 8, sem)
    guardar(nombre, rgb, a)

# ---------- huella de mano ----------
def huella(s, rnd, izq=False):
    """Una mano abierta de pie (dedos hacia arriba) en un lienzo de 3s × 3s."""
    L = int(s * 3)
    c = Image.new("L", (L, L), 0); d = ImageDraw.Draw(c)
    cx, cy = L / 2, L * 0.62
    pw, ph = s * 0.82, s * 0.86
    d.rounded_rectangle([cx - pw / 2, cy - ph * 0.45, cx + pw / 2, cy + ph * 0.55], radius=int(s * 0.28), fill=255)
    # dedos: índice, corazón, anular, meñique (de pulgar hacia fuera)
    dedos = [(-0.30, 0.78, 0.17), (-0.10, 0.92, 0.18), (0.11, 0.86, 0.17), (0.31, 0.66, 0.15)]
    sg = -1 if izq else 1
    for fx, l, r in dedos:
        x0 = cx + sg * fx * s; y0 = cy - ph * 0.40
        abre = sg * fx * 0.35 + rnd.uniform(-0.06, 0.06)
        x1 = x0 + math.sin(abre) * l * s; y1 = y0 - math.cos(abre) * l * s
        d.line([(x0, y0), (x1, y1)], 255, int(r * s))
        rr = r * s / 2
        d.ellipse([x1 - rr, y1 - rr, x1 + rr, y1 + rr], 255)
        # pliegues de las falanges (sin pintura)
        for k in (0.35, 0.68):
            px, py = x0 + (x1 - x0) * k, y0 + (y1 - y0) * k
            d.line([(px - rr * 0.9, py), (px + rr * 0.9, py)], 0, max(1, int(s * 0.02)))
    # pulgar
    x0 = cx - sg * pw * 0.42; y0 = cy + ph * 0.15
    x1 = x0 - sg * s * 0.42; y1 = y0 - s * 0.45
    d.line([(x0, y0), (x1, y1)], 255, int(s * 0.2))
    d.ellipse([x1 - s * 0.1, y1 - s * 0.1, x1 + s * 0.1, y1 + s * 0.1], 255)
    # líneas de la palma
    d.arc([cx - pw * 0.5, cy - ph * 0.3, cx + pw * 0.4, cy + ph * 0.5], 200, 300, 0, max(1, int(s * 0.03)))
    d.line([(cx - pw * 0.45, cy - ph * 0.12), (cx + pw * 0.45, cy - ph * 0.22)], 0, max(1, int(s * 0.025)))
    return c

def mano(m, cx, cy, s, ang, rnd, izq=False):
    h = huella(s, rnd, izq).rotate(math.degrees(-ang), Image.BICUBIC)
    m.paste(255, (int(cx - h.width / 2), int(cy - h.height / 2)), h)

def manos(nombre, n=3, c=(55, 10, 8), sem=11, w=1024, h=1024, arrastre=True):
    rnd = random.Random(sem)
    m = Image.new("L", (w, h), 0)
    for i in range(n):
        mano(m, rnd.uniform(w * 0.25, w * 0.75), rnd.uniform(h * 0.2, h * 0.5), rnd.uniform(130, 170), rnd.uniform(-0.35, 0.35), rnd, izq=i % 2 == 1)
    a = np.asarray(m, np.float32) / 255.0
    if arrastre:
        # la mano resbala hacia abajo: estela
        for k in range(1, 45):
            sh = np.roll(a, k * 5, axis=0) * (1 - k / 45) ** 2 * 0.45
            a = np.maximum(a, sh)
    n2 = ruido(w, h, 16, sem)
    a = np.clip(a * (0.55 + 0.6 * n2), 0, 1)
    a = np.asarray(Image.fromarray((a * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.5)), np.float32) / 255
    guardar(nombre, color_img(w, h, c, 0.4, sem), a * 0.9)

# ---------- círculo de sal viejo ----------
def sal(nombre, sem=13, w=1024, h=1024, roto=0.25):
    rng = np.random.default_rng(sem)
    yy, xx = np.mgrid[0:h, 0:w]
    r = np.hypot(xx - w / 2, yy - h / 2) / (w / 2)
    ang = np.arctan2(yy - h / 2, xx - w / 2)
    ancho = 0.035 + 0.02 * ruido(w, h, 64, sem)
    anillo = np.clip(1 - np.abs(r - 0.82) / ancho, 0, 1)
    hueco = np.ones_like(r)
    for _ in range(3):
        a0 = rng.uniform(-math.pi, math.pi)
        da = np.abs((ang - a0 + math.pi) % (2 * math.pi) - math.pi)
        hueco *= np.clip(da / (roto * rng.uniform(0.3, 1.0)), 0, 1)
    grano = (rng.random((h, w)) < 0.55).astype(np.float32)
    disperso = (rng.random((h, w)) < 0.02).astype(np.float32) * np.clip(1 - np.abs(r - 0.82) / 0.2, 0, 1)
    a = np.clip(anillo * hueco * (0.4 + 0.6 * grano) + disperso, 0, 1)
    rgb = np.dstack([a * 0 + 225, a * 0 + 222, a * 0 + 212]) * (0.8 + 0.2 * ruido(w, h, 8, sem)[..., None])
    guardar(nombre, rgb, a)

# ---------- símbolo del ritual (inventado) ----------
def simbolo(nombre, sem=17, c=(60, 8, 6), w=1024, h=1024):
    rnd = random.Random(sem)
    m = Image.new("L", (w, h), 0); d = ImageDraw.Draw(m)
    cx, cy = w / 2, h / 2
    def circ(r, t):
        pts = [(cx + math.cos(a) * r * (1 + rnd.uniform(-0.01, 0.01)), cy + math.sin(a) * r * (1 + rnd.uniform(-0.01, 0.01))) for a in np.linspace(0, 2 * math.pi, 120)]
        d.line(pts + [pts[0]], 255, t)
    circ(440, 14); circ(380, 8)
    # cuatro huecos de los sellos y la roca en el centro
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 4
        x, y = cx + math.cos(a) * 300, cy + math.sin(a) * 300
        d.ellipse([x - 55, y - 55, x + 55, y + 55], outline=255, width=10)
        d.line([(x, y), (cx, cy)], 255, 7)
    for k in range(7):
        a = k * 2 * math.pi / 7
        d.line([(cx + math.cos(a) * 380, cy + math.sin(a) * 380), (cx + math.cos(a + 2 * 2 * math.pi / 7) * 380, cy + math.sin(a + 2 * 2 * math.pi / 7) * 380)], 255, 6)
    d.ellipse([cx - 70, cy - 70, cx + 70, cy + 70], 255)
    f = ImageFont.truetype(FUENTE2, 46)
    for k, ch in enumerate("ZAREK·HIJO·DE·LA·ROCA·"):
        a = k / 22 * 2 * math.pi - math.pi / 2
        capa = Image.new("L", (70, 70), 0); ImageDraw.Draw(capa).text((14, 6), ch, 255, font=f)
        capa = capa.rotate(-math.degrees(a) - 90, Image.BICUBIC)
        m.paste(255, (int(cx + math.cos(a) * 410 - 35), int(cy + math.sin(a) * 410 - 35)), capa)
    a = np.asarray(m, np.float32) / 255 * (0.45 + 0.65 * ruido(w, h, 16, sem))
    a = np.asarray(Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2)), np.float32) / 255
    guardar(nombre, color_img(w, h, c, 0.35, sem), a * 0.9)

# ---------- dibujo infantil a ceras sobre papel ----------
def dibujo(nombre, tema, sem=19, w=512, h=640):
    rnd = random.Random(sem)
    papel = color_img(w, h, (226, 214, 184), 0.06, sem)
    # bordes amarillentos
    yy, xx = np.mgrid[0:h, 0:w]
    bord = np.clip(np.minimum(np.minimum(xx, w - xx), np.minimum(yy, h - yy)) / 40, 0, 1)
    papel *= (0.75 + 0.25 * bord)[..., None]
    img = Image.fromarray(papel.astype(np.uint8)); d = ImageDraw.Draw(img)
    def cera(pts, col, t=7):
        for k in range(3):
            j = [(x + rnd.uniform(-2, 2), y + rnd.uniform(-2, 2)) for x, y in pts]
            d.line(j, col, max(2, t - k * 2))
    def monigote(x, y, s, col, cara_negra=False, vestido=False):
        d.ellipse([x - 22 * s, y - 22 * s, x + 22 * s, y + 22 * s], outline=col, width=5)
        if cara_negra:
            d.ellipse([x - 20 * s, y - 20 * s, x + 20 * s, y + 20 * s], fill=(20, 18, 18))
            d.ellipse([x - 12 * s, y + 2 * s, x + 12 * s, y + 16 * s], fill=(150, 10, 10))
        else:
            d.point([(x - 8 * s, y - 4 * s), (x + 8 * s, y - 4 * s)], col)
            cera([(x - 8 * s, y + 8 * s), (x, y + 12 * s), (x + 8 * s, y + 8 * s)], col, 3)
        if vestido:
            cera([(x, y + 22 * s), (x - 30 * s, y + 90 * s), (x + 30 * s, y + 90 * s), (x, y + 22 * s)], col)
        else:
            cera([(x, y + 22 * s), (x, y + 80 * s)], col)
        cera([(x - 30 * s, y + 45 * s), (x + 30 * s, y + 45 * s)], col)
        cera([(x, y + 80 * s), (x - 20 * s, y + 130 * s)], col); cera([(x, y + 80 * s), (x + 20 * s, y + 130 * s)], col)
    if tema == "familia":
        cera([(0, 560), (w, 545)], (60, 130, 50), 10)
        d.ellipse([400, 30, 470, 100], outline=(230, 180, 20), width=8)
        for i, (x, col) in enumerate([(80, (40, 60, 160)), (170, (170, 40, 120)), (260, (40, 120, 60)), (340, (200, 120, 30))]):
            monigote(x, 360, 1.0 - i * 0.1, col, vestido=i in (1, 3))
        monigote(450, 330, 1.25, (15, 12, 12), cara_negra=True, vestido=True)
    elif tema == "casa":
        cera([(0, 590), (w, 580)], (60, 130, 50), 10)
        cera([(110, 560), (110, 300), (400, 300), (400, 560), (110, 560)], (120, 70, 40), 8)
        cera([(90, 300), (255, 150), (420, 300)], (160, 30, 30), 8)
        for wx in (150, 320):
            d.rectangle([wx, 340, wx + 50, 400], outline=(40, 40, 40), width=5)
        d.rectangle([320, 340, 370, 400], fill=(10, 10, 10))
        d.ellipse([330, 355, 340, 365], fill=(240, 240, 240)); d.ellipse([350, 355, 360, 365], fill=(240, 240, 240))
        cera([(230, 560), (230, 470), (280, 470), (280, 560)], (40, 30, 20), 7)
        d.ellipse([60, 30, 140, 110], outline=(220, 220, 200), width=6)
    elif tema == "ojos":
        for k in range(26):
            x, y = rnd.uniform(40, w - 40), rnd.uniform(60, h - 60)
            d.ellipse([x - 22, y - 12, x + 22, y + 12], outline=(10, 10, 10), width=4)
            d.ellipse([x - 5, y - 5, x + 5, y + 5], fill=(10, 10, 10))
        f = ImageFont.truetype(FUENTE, 40)
        d.text((60, h - 90), "ME MIRAN", (150, 20, 20), font=f)
    elif tema == "pozo":
        cera([(0, 300), (w, 290)], (60, 130, 50), 10)
        d.ellipse([150, 260, 360, 330], outline=(80, 80, 80), width=8)
        d.ellipse([170, 270, 340, 320], fill=(10, 10, 10))
        for k in range(5):
            x = 200 + k * 30
            cera([(x, 300), (x - 10 + rnd.uniform(-10, 10), 210)], (230, 230, 220), 4)
        monigote(256, 420, 1.0, (40, 60, 160))
        f = ImageFont.truetype(FUENTE, 34)
        d.text((40, 560), "ÉL VIVE ABAJO", (20, 20, 20), font=f)
    a = np.ones((h, w), np.float32)
    guardar(nombre, np.asarray(img, np.float32), a)

# ---------- rayas sobre un retrato ----------
def rayado(nombre, sem=23, w=512, h=512):
    rng = np.random.default_rng(sem)
    rgb = np.zeros((h, w, 3), np.float32); a = np.zeros((h, w), np.float32)
    yy, xx = np.mgrid[0:h, 0:w]
    cx, cy = w * 0.5, h * 0.38
    for _ in range(26):
        ang = rng.uniform(-1.2, 1.2) + math.pi / 2 * rng.integers(0, 2)
        l = rng.uniform(80, 200)
        x0 = cx + rng.uniform(-70, 70); y0 = cy + rng.uniform(-80, 80)
        dx, dy = math.cos(ang), math.sin(ang)
        t = (xx - x0) * dx + (yy - y0) * dy
        dist = np.abs(-(xx - x0) * dy + (yy - y0) * dx)
        m = np.clip(1 - dist / rng.uniform(1.5, 3.5), 0, 1) * (np.abs(t) < l)
        a = np.maximum(a, m)
    # la cara tachada del todo: mancha
    cara = np.clip(1 - np.hypot((xx - cx) / 70, (yy - cy) / 90), 0, 1) ** 0.5
    a = np.maximum(a, cara * (ruido(w, h, 8, sem) > 0.45) * 0.95)
    rgb[:] = (205, 190, 165)
    rgb = np.where((cara > 0.2)[..., None], np.array([25, 18, 14], np.float32), rgb)
    guardar(nombre, rgb, a)

# ---------- grietas de espejo ----------
def grietas(nombre, sem=29, w=1024, h=1024):
    rnd = random.Random(sem)
    m = Image.new("L", (w, h), 0); d = ImageDraw.Draw(m)
    cx, cy = w * rnd.uniform(0.4, 0.6), h * rnd.uniform(0.35, 0.55)
    radios = []
    for k in range(17):
        a = k / 17 * 2 * math.pi + rnd.uniform(-0.15, 0.15)
        pts = [(cx, cy)]; r = 0
        while r < w:
            r += rnd.uniform(40, 110); a += rnd.uniform(-0.2, 0.2)
            pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
        radios.append(pts)
        d.line(pts, 255, 3)
    for ring in [70, 160, 280, 420]:
        for k in range(len(radios)):
            p0 = radios[k]; p1 = radios[(k + 1) % len(radios)]
            i = min(len(p0) - 1, len(p1) - 1, int(ring / 75))
            if rnd.random() < 0.7:
                d.line([p0[i], p1[i]], 255, 2)
    d.ellipse([cx - 25, cy - 25, cx + 25, cy + 25], 255)
    a = np.asarray(m.filter(ImageFilter.GaussianBlur(0.8)), np.float32) / 255
    rgb = np.full((h, w, 3), 235.0)
    guardar(nombre, rgb, a * 0.85)

# ---------- mancha de humedad ----------
def humedad(nombre, sem=31, w=1024, h=1024):
    n = ruido(w, h, 256, sem)
    yy, xx = np.mgrid[0:h, 0:w]
    caida = np.clip(1 - np.hypot((xx - w / 2) / (w * 0.45), (yy - h * 0.3) / (h * 0.7)), 0, 1)
    v = n * caida
    a = np.clip((v - 0.15) * 2.2, 0, 1)
    borde = np.clip(1 - np.abs(v - 0.2) / 0.03, 0, 1) * 0.5
    rgb = color_img(w, h, (70, 62, 40), 0.3, sem)
    guardar(nombre, rgb, np.clip(a * 0.55 + borde, 0, 0.8))

# ---------- agua sucia (mapa de color para la bañera) ----------
def agua(nombre, sem=37, w=512, h=512):
    n = ruido(w, h, 64, sem)
    rgb = np.dstack([40 + 30 * n, 36 + 22 * n, 18 + 10 * n])
    guardar(nombre, rgb, np.ones((h, w)))

# ---------- nombre grabado en una lápida ----------
def lapida(nombre_archivo, nombre, fechas, w=512, h=340):
    m = Image.new("L", (w, h), 0); d = ImageDraw.Draw(m)
    lineas = [("+", 64, FUENTE2), (nombre, 40, FUENTE2), (fechas, 36, FUENTE2), ("R. I. P.", 30, FUENTE2)]
    y = 16
    for txt, t, fu in lineas:
        f = ImageFont.truetype(fu, t)
        while f.getlength(txt) > w * 0.92 and t > 16:
            t -= 2; f = ImageFont.truetype(fu, t)
        d.text(((w - f.getlength(txt)) / 2, y), txt, 255, font=f)
        y += int(t * 1.4)
    a = np.asarray(m, np.float32) / 255
    luz = np.roll(a, 2, axis=0) * (1 - a)  # borde claro abajo: la luz roza el grabado
    rgb = np.zeros((h, w, 3), np.float32)
    rgb[:] = (18, 17, 15)
    rgb = np.where((luz > a)[..., None], np.array([190, 188, 180], np.float32), rgb)
    alfa = np.clip(a * 1.0 + luz * 0.5, 0, 1) * (0.7 + 0.3 * ruido(w, h, 16, len(nombre)))
    guardar(nombre_archivo, rgb, alfa)

TUMBAS = [("lap_aurelio", "AURELIO VARELA", "1821 - 1889"), ("lap_esteban", "JULIÁN VARELA", "1950 - 1987"), ("lap_isabel", "DAMIÁN VARELA", "1978 - 1987"),
          ("lap_tomas", "INÉS VARELA", "1962 - ?"), ("lap_clara", "ROSA VARELA", "1931 - 1980"), ("lap_marta", "MARTA ESCOBAR", "INSTITUTRIZ · 1987"), ("lap_elena", "ELENA VARELA", "1957 - 1987")]

if __name__ == "__main__":
    import os
    os.makedirs(OUT, exist_ok=True)
    escrito("esc_sigue_aqui", "MAMÁ TIENE\nHAMBRE", sem=1)
    escrito("esc_no_mires", "NO MIRES\nATRÁS", sem=2)
    escrito("esc_perdonanos", "PERDÓNAME MAMÁ", c=(35, 30, 28), sem=3, w=1024, h=256, goteo=False)
    escrito("esc_no_abras", "NO LA\nSUELTES", sem=4)
    escrito("esc_zarek", "BIENVENIDA\nA CASA SOFÍA", c=(70, 10, 8), sem=8)
    escrito("esc_1974", "13·XI·1987", c=(60, 10, 8), sem=9, w=1024, h=256)
    escrito("esc_clara", "NO ME\nCOMAS", c=(45, 50, 120), sem=10, goteo=False, fuente=FUENTE2)
    escrito("esc_ya_viene", "YA VIENE", sem=12, w=1024, h=256)
    escrito("esc_la_sal", "LA LUZ\nLO CIEGA", c=(35, 30, 28), sem=14, goteo=False)
    palotes("esc_palotes")
    aranazos("aranazos_1", sem=7); aranazos("aranazos_2", sem=8, grupos=2); aranazos("aranazos_puerta", sem=9, grupos=5, w=512, h=1024)
    manos("manos_sangre", n=3, sem=11); manos("manos_sucias", n=4, c=(40, 34, 26), sem=12); manos("mano_nina", n=2, c=(50, 12, 10), sem=15, arrastre=False)
    sal("sal_vieja_1", sem=13, roto=0.6); sal("sal_vieja_2", sem=14, roto=1.0)
    simbolo("simbolo_ritual")
    for t in ("familia", "casa", "ojos", "pozo"):
        dibujo("dibujo_" + t, t, sem=hash(t) % 97)
    rayado("rayado_1", sem=23); rayado("rayado_2", sem=24)
    grietas("grietas_espejo")
    humedad("humedad_1", sem=31); humedad("humedad_2", sem=32)
    agua("agua_sucia")
    for t in TUMBAS:
        lapida(*t)
    print("ok")
