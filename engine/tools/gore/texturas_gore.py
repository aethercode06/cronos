"""Texturas de sangre y carne para La Sombra de Zarek (calcomanías con alfa y materiales opacos).
Uso: python3 texturas_gore.py <carpeta_salida>"""
import sys, numpy as np
from PIL import Image, ImageFilter
OUT = sys.argv[1]
rng = np.random.default_rng(666)

def ruido(n, esc, sem, oct_=5):
    r = np.random.default_rng(sem); acc = np.zeros((n, n), np.float32); amp = 1.0; tot = 0
    for o in range(oct_):
        k = max(int(esc * 2 ** o), 2)
        g = r.random((k, k)).astype(np.float32)
        im = Image.fromarray((g * 255).astype(np.uint8)).resize((n, n), Image.BICUBIC)
        acc += np.asarray(im, np.float32) / 255 * amp; tot += amp; amp *= 0.5
    return acc / tot

def color_sangre(n, sem, seca):
    # sangre: roja oscura en el centro, casi negra en los bordes secos, con brillos apagados
    v = ruido(n, 6, sem, 4)
    fresca = np.array([0.36, 0.02, 0.02]); vieja = np.array([0.14, 0.02, 0.015])
    mez = np.clip(seca + (v - 0.5) * 0.6, 0, 1)[..., None]
    return fresca * (1 - mez) + vieja * mez

def guardar(nombre, rgb, a):
    img = np.dstack([np.clip(rgb, 0, 1), np.clip(a, 0, 1)])
    Image.fromarray((img * 255).astype(np.uint8), "RGBA").save(f"{OUT}/{nombre}.png")

def charco(nombre, sem, n=512):
    y, x = np.mgrid[0:n, 0:n] / n - 0.5
    r = np.sqrt(x * x + y * y)
    ang = np.arctan2(y, x)
    borde = 0.3 + 0.08 * np.sin(ang * 3 + sem) + 0.05 * np.sin(ang * 7 + sem * 2) + (ruido(n, 4, sem) - 0.5) * 0.18
    a = np.clip((borde - r) * 30, 0, 1)
    # gotas sueltas alrededor
    rr = np.random.default_rng(sem)
    for k in range(40):
        cx, cy = rr.uniform(-0.45, 0.45, 2); rad = rr.uniform(0.005, 0.025)
        a = np.maximum(a, np.clip((rad - np.sqrt((x - cx) ** 2 + (y - cy) ** 2)) * 400, 0, 1))
    seca = np.clip(r / 0.35, 0, 1) * 0.7
    guardar(nombre, color_sangre(n, sem, seca), a * 0.95)

def salpicadura(nombre, sem, n=512):
    y, x = np.mgrid[0:n, 0:n] / n - 0.5
    a = np.zeros((n, n), np.float32)
    rr = np.random.default_rng(sem)
    cx, cy = rr.uniform(-0.1, 0.1, 2)
    a = np.maximum(a, np.clip((0.09 - np.sqrt((x - cx) ** 2 + (y - cy) ** 2) - (ruido(n, 8, sem) - 0.5) * 0.06) * 60, 0, 1))
    for k in range(120):  # gotas proyectadas en todas direcciones, alargadas hacia fuera
        ang = rr.uniform(0, 2 * np.pi); dist = rr.uniform(0.05, 0.45) ** 0.8
        px, py = cx + np.cos(ang) * dist, cy + np.sin(ang) * dist
        rad = rr.uniform(0.004, 0.02) * (1.2 - dist)
        dx, dy = x - px, y - py
        u = dx * np.cos(ang) + dy * np.sin(ang); v = -dx * np.sin(ang) + dy * np.cos(ang)
        a = np.maximum(a, np.clip((rad - np.sqrt((u / 2.2) ** 2 + v ** 2)) * 500, 0, 1))
    guardar(nombre, color_sangre(n, sem, 0.35), a)

def arrastre(nombre, sem, w=256, h=1024):
    # rastro de algo arrastrado: franja irregular con estrías a lo largo, manchas y huellas de dedos
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    xn = x / w - 0.5
    ancho = 0.32 + (ruido(h, 3, sem)[:, :1].repeat(w, 1)[:h, :w] - 0.5) * 0.25 if False else 0.3
    n1 = np.asarray(Image.fromarray((ruido(256, 3, sem) * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC), np.float32) / 255
    estria = np.asarray(Image.fromarray((np.random.default_rng(sem).random((8, 64)) * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC), np.float32) / 255
    a = np.clip((0.3 + (n1 - 0.5) * 0.35 - np.abs(xn)) * 12, 0, 1)
    a *= np.clip(0.35 + estria * 0.9, 0, 1)
    # el rastro se aclara y se corta al final (para encadenar varios)
    a *= np.clip(np.sin(np.linspace(0, np.pi, h))[:, None] * 3, 0, 1)
    guardar(nombre, color_sangre(1024, sem, 0.5)[:h, :w], a)

def goteo(nombre, sem, w=512, h=1024):
    # mancha en la pared con chorretones que bajan
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    xn = x / w - 0.5; yn = y / h
    rr = np.random.default_rng(sem)
    ang = np.arctan2((yn - 0.18) * 1.8, xn)
    rad = 0.2 + 0.05 * np.sin(ang * 5 + sem) + 0.035 * np.sin(ang * 11 + sem * 3)
    a = np.clip((rad - np.sqrt(xn ** 2 + ((yn - 0.18) * 1.8) ** 2)) * 25, 0, 1)
    nm = np.asarray(Image.fromarray((ruido(512, 6, sem) * 255).astype(np.uint8)).resize((w, h)), np.float32) / 255
    a = np.clip(a + (nm - 0.5) * 0.6 * (a > 0.05), 0, 1)
    for k in range(14):
        cx = rr.uniform(-0.2, 0.2); largo = rr.uniform(0.3, 0.8); grosor = rr.uniform(0.006, 0.018)
        dentro = (np.abs(xn - cx) < grosor * (1.2 - (yn - 0.2) / largo * 0.5)) & (yn > 0.15) & (yn < 0.2 + largo)
        a = np.maximum(a, dentro.astype(np.float32))
        gota = np.clip((grosor * 1.8 - np.sqrt((xn - cx) ** 2 + ((yn - 0.2 - largo) * 0.6) ** 2)) * 300, 0, 1)
        a = np.maximum(a, gota)
    guardar(nombre, color_sangre(1024, sem, 0.4)[:h, :w], a)

def pisadas(nombre, sem, w=256, h=1024):
    # pisadas de pies descalzos ensangrentados (Damián va descalzo), alternando izquierda y derecha
    y, x = np.mgrid[0:h, 0:w].astype(np.float32) / w
    a = np.zeros((h, w), np.float32)
    rr = np.random.default_rng(sem)
    for k in range(4):
        lado = 1 if k % 2 else -1
        cx, cy = 0.5 + lado * 0.15, 0.5 + k * 1.0
        planta = np.clip((0.14 - np.sqrt(((x - cx) / 0.75) ** 2 + ((y - cy - 0.05) / 1.6) ** 2)) * 60, 0, 1)
        talon = np.clip((0.1 - np.sqrt((x - cx) ** 2 + (y - cy - 0.4) ** 2)) * 70, 0, 1)
        a = np.maximum(a, np.maximum(planta, talon))
        for d in range(5):
            dx = cx + lado * (-0.08 + d * 0.042) * -1
            a = np.maximum(a, np.clip((0.032 - np.sqrt((x - dx * 1.0) ** 2 + (y - cy + 0.2 - abs(d - 1.5) * 0.015) ** 2)) * 250, 0, 1))
    a *= 0.85 - np.linspace(0, 0.35, h)[:, None]  # cada vez menos sangre en el pie
    guardar(nombre, color_sangre(1024, sem, 0.55)[:h, :w], a)

def opaca(nombre, rgb):
    Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8)).save(f"{OUT}/{nombre}.png")

def carne(n=512):
    # carne cruda: rojo con vetas de grasa y tendones, zonas oscuras secas
    f = ruido(n, 5, 11, 6); g = ruido(n, 18, 12, 3)
    vetas = np.clip(1 - np.abs(np.sin(f * 18 + g * 4)) * 4, 0, 1)
    base = np.array([0.45, 0.06, 0.06]) * (0.75 + 0.5 * g[..., None])
    grasa = np.array([0.78, 0.66, 0.55])
    rgb = base * (1 - vetas[..., None] * 0.7) + grasa * vetas[..., None] * 0.7
    seco = np.clip((ruido(n, 4, 13) - 0.55) * 4, 0, 1)[..., None]
    opaca("carne", rgb * (1 - seco * 0.55))

def tela_sangre(n=512):
    # sábana sucia empapada de sangre por manchas (para cuerpos tapados)
    base = np.array([0.7, 0.66, 0.58]) * (0.85 + 0.2 * ruido(n, 30, 21, 3)[..., None])
    m = ruido(n, 4, 22, 5)
    sangre = np.clip((m - 0.5) * 5, 0, 1)[..., None]
    halo = np.clip((m - 0.42) * 6, 0, 1)[..., None] - sangre
    rgb = base * (1 - halo * 0.5) + np.array([0.45, 0.25, 0.15]) * halo * 0.5
    rgb = rgb * (1 - sangre) + color_sangre(n, 23, 0.4) * sangre
    opaca("tela_sangre", rgb)

def plastico(n=512):
    # plástico negro de envolver, con arrugas y sangre por dentro
    arr = ruido(n, 20, 31, 4)
    rgb = np.array([0.04, 0.04, 0.045]) + np.clip((arr - 0.5) * 0.25, 0, 1)[..., None]
    s = np.clip((ruido(n, 5, 32) - 0.62) * 5, 0, 1)[..., None]
    opaca("plastico", rgb * (1 - s) + np.array([0.2, 0.01, 0.01]) * s)

def hueso(n=256):
    v = ruido(n, 12, 41, 4)
    opaca("hueso", np.array([0.78, 0.72, 0.6]) * (0.8 + 0.3 * v[..., None]) - np.clip((ruido(n, 4, 42) - 0.6) * 2, 0, 1)[..., None] * np.array([0.3, 0.4, 0.4]))

for k in range(3): charco(f"sangre_charco_{k+1}", 100 + k)
for k in range(3): salpicadura(f"sangre_salpicadura_{k+1}", 200 + k)
for k in range(2): arrastre(f"sangre_arrastre_{k+1}", 300 + k)
for k in range(2): goteo(f"sangre_goteo_{k+1}", 400 + k)
pisadas("sangre_pisadas", 500)
carne(); tela_sangre(); plastico(); hueso()
print("texturas de sangre listas")
