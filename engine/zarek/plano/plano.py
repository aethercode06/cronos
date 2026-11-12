"""Plano de la mansión Varela (La Sombra de Zarek).
Cada celda = 3 m. Genera plano.json (para construir el juego) y las imágenes del plano.
Uso: python3 plano.py <carpeta_salida>"""
import json, sys, os
from PIL import Image, ImageDraw, ImageFont

OUT = sys.argv[1] if len(sys.argv) > 1 else "."
os.makedirs(OUT, exist_ok=True)

# tipo -> color de relleno
COL = {
    "pasillo": (58, 52, 46), "sala": (92, 70, 52), "dormitorio": (88, 60, 66), "servicio": (70, 72, 62),
    "epicentro": (120, 24, 28), "sotano": (60, 58, 66), "tunel": (44, 44, 52), "roca": (70, 20, 24),
    "bosque": (24, 46, 30), "jardin": (40, 68, 40), "camino": (98, 84, 62), "edificio": (78, 70, 60), "agua": (40, 60, 80),
}

# (nombre, tipo, x, y, ancho, alto)
PLANTAS = {
"exterior": {
    "titulo": "EXTERIOR · La mansión en medio del bosque", "w": 100, "h": 112,
    "zonas": [
        ("Bosque de pinos", "bosque", 0, 0, 100, 112),
        ("Terrenos de la mansión (jardines salvajes, muro de piedra)", "jardin", 20, 12, 60, 64),
        ("Jardín trasero", "jardin", 22, 14, 56, 14),
        ("Laberinto de setos", "bosque", 50, 15, 16, 11),
        ("Caseta del jardinero", "edificio", 24, 16, 6, 5),
        ("Estanque", "agua", 34, 17, 10, 6),
        ("MANSIÓN VICTORIANA", "edificio", 35, 30, 30, 22),
        ("Porche", "camino", 37, 52, 26, 2),
        ("Torre", "edificio", 32, 46, 6, 7),
        ("Invernadero", "edificio", 68, 30, 9, 11),
        ("Cochera", "edificio", 68, 44, 9, 9),
        ("Pozo (aljibe)", "agua", 25, 38, 4, 4),
        ("Huerto seco", "camino", 23, 46, 9, 7),
        ("Jardín delantero", "jardin", 22, 53, 56, 21),
        ("Fuente", "agua", 46, 57, 8, 5),
        ("Camino de entrada", "camino", 48, 52, 4, 23),
        ("Portón", "camino", 47, 75, 6, 1),
        ("Camino del bosque", "camino", 49, 76, 3, 8),
        ("Camino del bosque", "camino", 36, 83, 16, 3),
        ("Camino del bosque", "camino", 36, 85, 3, 12),
        ("Camino del bosque", "camino", 36, 96, 22, 3),
        ("Camino del bosque", "camino", 55, 98, 3, 14),
        ("Arroyo", "agua", 0, 90, 100, 2),
        ("Puente viejo", "camino", 35, 89, 5, 4),
        ("Sendero", "camino", 39, 84, 30, 2),
        ("Cabaña del cazador", "edificio", 69, 80, 9, 7),
        ("Claro del columpio", "camino", 12, 64, 6, 6),
        ("Sendero", "camino", 6, 66, 6, 2),
        ("Sendero", "camino", 6, 66, 2, 20),
        ("Sendero", "camino", 6, 84, 30, 2),
        ("Árbol de los cuervos", "camino", 84, 20, 6, 6),
        ("Sendero", "camino", 78, 22, 6, 2),
    ],
    "marcas": [("inicio", 56.5, 109, "INICIO: el coche averiado en la carretera"), ("sello", 72.5, 35, "Sello 4"),
               ("armario", 27, 18.5, ""), ("armario", 73, 83, ""), ("susto", 15, 71.5, "Columpio que se mueve solo"),
               ("susto", 87, 27.5, ""), ("susto", 41.5, 92.5, "Algo cruza el puente"),
               ("puerta", 50, 52, "Entrada principal"), ("puerta", 50, 30, "Puerta trasera"),
               ("tunel", 27, 43.3, ""), ("tunel", 72.5, 49, ""), ("nota", 73, 85, "Nota del cazador")],
},
"baja": {
    "titulo": "PLANTA BAJA", "w": 30, "h": 22,
    "zonas": [
        ("Pasillo principal", "pasillo", 1, 11, 28, 2),
        ("Vestíbulo y gran escalera", "sala", 11, 13, 8, 9),
        ("Salón con chimenea", "sala", 1, 13, 10, 9),
        ("Torre (escalera de caracol)", "sala", 1, 18, 4, 4),
        ("Comedor formal", "sala", 19, 13, 6, 9),
        ("Cocina", "servicio", 25, 13, 4, 5),
        ("Despensa", "servicio", 25, 18, 4, 4),
        ("Biblioteca", "sala", 1, 3, 7, 8),
        ("Estudio del padre", "sala", 8, 3, 4, 8),
        ("Salón de baile", "sala", 12, 0, 10, 11),
        ("Sala de fumar y billar", "sala", 22, 5, 7, 6),
        ("Cuarto de servicio", "servicio", 22, 0, 7, 5),
        ("Baño", "servicio", 1, 0, 4, 3),
        ("Sala de las mañanas", "sala", 5, 0, 7, 3),
    ],
    "puertas": [("h", 15, 22), ("h", 4, 11), ("h", 10, 11), ("h", 16, 11), ("h", 25, 11),
                ("h", 6, 13), ("h", 15, 13), ("h", 21, 13), ("h", 27, 13), ("v", 11, 17), ("v", 19, 17),
                ("v", 25, 15), ("h", 27, 18), ("h", 25, 5), ("v", 22, 2), ("v", 5, 1), ("h", 6, 3), ("h", 9, 3),
                ("v", 12, 1), ("h", 17, 0), ("v", 5, 19)],
    "marcas": [("escalera", 15, 18.5, "Gran escalera"), ("escalera", 27, 20, "Sótano ↓"),
               ("escalera", 27.5, 1.5, "Servicio ↑"), ("pasadizo", 9.5, 9.6, "Pasadizo secreto"),
               ("sello", 17, 5, "Sello 1"), ("armario", 3, 20, ""), ("armario", 23.5, 8, ""), ("armario", 2, 5, ""),
               ("armario", 26, 13.8, ""), ("lampara", 6, 17, ""), ("lampara", 17, 6, ""), ("lampara", 22, 17, ""),
               ("radio", 8.5, 15.3, "Radio"), ("piano", 14, 2, "Piano"), ("chimenea", 2.5, 16.3, "Chimenea"),
               ("chimenea", 4.5, 10.4, "Chimenea"), ("chimenea", 22, 20.5, "Chimenea"), ("escalera", 3, 20.2, "")],
},
"alta": {
    "titulo": "PRIMER PISO", "w": 30, "h": 22,
    "zonas": [
        ("Pasillo", "pasillo", 1, 11, 28, 2),
        ("Galería de retratos", "sala", 11, 13, 8, 5),
        ("Balcón", "jardin", 12, 18, 6, 3),
        ("EPICENTRO · cuarto de Elena", "epicentro", 11, 2, 8, 9),
        ("Dormitorio de los padres", "dormitorio", 1, 2, 7, 9),
        ("Tocador de la madre", "dormitorio", 8, 2, 3, 9),
        ("Cuarto del hermano", "dormitorio", 19, 2, 5, 9),
        ("Cuarto de niños", "dormitorio", 24, 2, 5, 9),
        ("Sala de costura", "sala", 1, 13, 7, 6),
        ("Torre", "sala", 1, 15, 4, 4),
        ("Baño", "servicio", 8, 13, 3, 4),
        ("Cuarto de huéspedes", "dormitorio", 19, 13, 6, 6),
        ("Escalera de servicio", "servicio", 25, 13, 4, 4),
    ],
    "puertas": [("h", 4, 11), ("h", 9, 11), ("h", 15, 11), ("h", 21, 11), ("h", 26, 11),
                ("h", 4, 13), ("h", 9, 13), ("h", 15, 13), ("h", 21, 13), ("h", 27, 13),
                ("h", 15, 18), ("v", 8, 6), ("v", 24, 6), ("v", 5, 16)],
    "marcas": [("escalera", 15, 15, "Gran escalera"), ("escalera", 26, 15.8, "Ático ↑"),
               ("sello", 3, 4, "Sello 2"), ("circulo", 15, 7, ""),
               ("armario", 6.5, 9, ""), ("armario", 20, 9, ""), ("armario", 27.5, 9, ""), ("escalera", 3, 17, ""), ("chimenea", 4.5, 2.5, "Chimenea"),
               ("armario", 23.5, 17.5, ""), ("lampara", 4, 15, ""), ("lampara", 21.5, 15, ""), ("espejo", 9.5, 4, "Espejo"),
               ("caja", 26.5, 6, "Caja de música")],
},
"atico": {
    "titulo": "ÁTICO Y MIRADOR DE LA TORRE", "w": 30, "h": 14,
    "zonas": [
        ("Ático (vigas, baúles, muñecos tapados)", "servicio", 6, 2, 18, 10),
        ("Rincón de Elena", "epicentro", 7, 3, 4, 3),
        ("Mirador de la torre", "sala", 1, 7, 4, 5),
    ],
    "puertas": [],
    "marcas": [("escalera", 22, 10, "Escalera de servicio"), ("armario", 12, 10, ""), ("armario", 19, 3, ""),
               ("nota", 9, 4.5, "Diario de Elena (1974)"), ("escalera", 3, 10.5, "")],
},
"sotano": {
    "titulo": "SÓTANO Y TÚNELES", "w": 50, "h": 30,
    "zonas": [
        ("Pasillo del sótano", "sotano", 18, 11, 22, 2),
        ("Archivo", "sotano", 18, 13, 7, 7),
        ("Sala de calderas", "sotano", 25, 13, 7, 7),
        ("Cava de vinos", "sotano", 32, 13, 8, 7),
        ("Galería de servicio", "sotano", 24, 4, 8, 7),
        ("Túnel oeste", "tunel", 5, 11, 13, 2),
        ("Túnel este", "tunel", 40, 11, 6, 2),
        ("Túnel este", "tunel", 44, 13, 2, 10),
        ("Túnel profundo", "tunel", 21, 20, 2, 5),
        ("Pozo (sale al jardín)", "agua", 2, 9, 3, 6),
        ("Salida a la cochera", "tunel", 43, 23, 4, 3),
        ("Cámara de la roca madre", "roca", 15, 25, 14, 5),
    ],
    "puertas": [("h", 21, 13), ("h", 28, 13), ("h", 36, 13), ("h", 28, 11), ("v", 18, 12), ("v", 40, 12),
                ("h", 22, 20), ("h", 22, 25), ("v", 5, 12)],
    "marcas": [("escalera", 36, 18.5, "Despensa ↑"), ("pasadizo", 29, 5, "Pasadizo al estudio del padre"),
               ("sello", 34.5, 15.5, "Sello 3"), ("armario", 19, 18, ""), ("armario", 30, 6, ""), ("armario", 26.5, 18.5, ""),
               ("lampara", 28.5, 16, ""), ("roca", 27, 28.5, "Cerrada (próximas noches)"),
               ("tunel", 3.5, 13.5, ""), ("tunel", 45, 25, "")],
},
}

json.dump(PLANTAS, open(os.path.join(OUT, "plano.json"), "w"), ensure_ascii=False, indent=1)

F = "/usr/share/fonts/truetype/dejavu/"
def font(sz, bold=False):
    return ImageFont.truetype(F + ("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"), sz)

ICON = {"inicio": (80, 220, 120), "sello": (255, 200, 60), "armario": (150, 110, 70), "escalera": (230, 230, 230),
        "lampara": (255, 220, 140), "pasadizo": (180, 120, 255), "circulo": (240, 240, 230), "tunel": (120, 170, 255),
        "susto": (220, 60, 60), "puerta": (210, 170, 110), "radio": (200, 200, 200), "piano": (200, 200, 200),
        "espejo": (170, 200, 230), "caja": (230, 180, 200), "nota": (230, 220, 180), "roca": (230, 70, 70), "chimenea": (230, 110, 50)}

def draw(key, C):
    p = PLANTAS[key]
    W, H = p["w"] * C + 300, p["h"] * C + 140
    im = Image.new("RGB", (W, H), (14, 12, 12))
    d = ImageDraw.Draw(im)
    ox, oy = 40, 90
    d.text((40, 24), p["titulo"], fill=(220, 60, 50), font=font(34, True))
    d.text((40, 64), "1 cuadro = 3 m", fill=(140, 130, 120), font=font(16))
    # cuadrícula
    for x in range(p["w"] + 1):
        d.line([(ox + x * C, oy), (ox + x * C, oy + p["h"] * C)], fill=(26, 24, 24))
    for y in range(p["h"] + 1):
        d.line([(ox, oy + y * C), (ox + p["w"] * C, oy + y * C)], fill=(26, 24, 24))
    for (n, t, x, y, w, h) in p["zonas"]:
        r = [ox + x * C, oy + y * C, ox + (x + w) * C, oy + (y + h) * C]
        wall = (20, 16, 14) if t not in ("bosque",) else (24, 46, 30)
        d.rectangle(r, fill=COL[t], outline=wall if t != "bosque" else None, width=4)
        if t == "bosque":
            import random
            rnd = random.Random(3)
            for i in range(int(900 * (r[2] - r[0]) * (r[3] - r[1]) / 1.2e6) + 200):
                tx, ty = rnd.uniform(r[0], r[2]), rnd.uniform(r[1], r[3])
                d.ellipse([tx - 5, ty - 5, tx + 5, ty + 5], fill=(14, 34, 20))
    for (n, t, x, y, w, h) in p["zonas"]:
        if (t == "bosque" and n != "Laberinto de setos") or n in ("Camino del bosque", "Sendero", "Camino de entrada", "Arroyo"):
            continue
        fs = 17 if w * C > 170 else 13
        if C < 20:
            fs = 15 if w * C > 150 else 12
        if n.startswith("MANSIÓN"):
            fs = 30
        cx, cy = ox + (x + w / 2) * C, oy + (y + h / 2) * C
        if h >= 4 and not n.startswith("MANSIÓN"):
            cy = oy + y * C + 14 + fs * 1.2
        lines = []
        cur = ""
        for word in n.split(" "):
            if d.textlength(cur + " " + word, font=font(fs, True)) > w * C - 8 and cur:
                lines.append(cur); cur = word
            else:
                cur = (cur + " " + word).strip()
        lines.append(cur)
        ty = cy - len(lines) * (fs + 2) / 2
        for ln in lines:
            tw = d.textlength(ln, font=font(fs, True))
            d.text((cx - tw / 2, ty), ln, fill=(235, 225, 210), font=font(fs, True))
            ty += fs + 2
    for (k, x, y) in p.get("puertas", []):
        if k == "h":
            d.rectangle([ox + x * C + 4, oy + y * C - 5, ox + (x + 1) * C - 4, oy + y * C + 5], fill=(190, 140, 80))
        else:
            d.rectangle([ox + x * C - 5, oy + y * C + 4, ox + x * C + 5, oy + (y + 1) * C - 4], fill=(190, 140, 80))
    if key == "exterior":
        # el camino también entra al claro
        pass
    for (k, x, y, txt) in p.get("marcas", []):
        px, py = ox + x * C, oy + y * C
        c = ICON[k]
        if k == "sello":
            d.regular_polygon((px, py, 13), 5, fill=c, outline=(80, 50, 0))
        elif k == "inicio":
            d.polygon([(px - 12, py + 10), (px + 12, py + 10), (px, py - 14)], fill=c)
        elif k == "armario":
            d.rectangle([px - 8, py - 11, px + 8, py + 11], fill=c, outline=(40, 25, 15), width=2)
            d.line([(px, py - 9), (px, py + 9)], fill=(40, 25, 15), width=2)
        elif k == "escalera":
            for i in range(5):
                d.line([(px - 13, py - 12 + i * 6), (px + 13, py - 12 + i * 6)], fill=c, width=3)
        elif k == "lampara":
            d.ellipse([px - 8, py - 8, px + 8, py + 8], fill=c)
        elif k == "circulo":
            d.ellipse([px - 40, py - 40, px + 40, py + 40], outline=c, width=5)
            d.regular_polygon((px, py, 34), 5, outline=c)
        else:
            d.ellipse([px - 9, py - 9, px + 9, py + 9], fill=c, outline=(0, 0, 0), width=2)
        if txt:
            d.text((px + 16, py - 9), txt, fill=c, font=font(15, True))
    return im

def legend(Wd):
    items = [("inicio", "Inicio"), ("sello", "Sello"), ("armario", "Armario (esconderse)"), ("escalera", "Escalera"),
             ("lampara", "Lámpara"), ("pasadizo", "Pasadizo secreto"), ("tunel", "Túnel / conexión"), ("circulo", "Ritual")]
    im = Image.new("RGB", (Wd, 120), (14, 12, 12))
    d = ImageDraw.Draw(im)
    x, y = 40, 20
    for k, t in items:
        c = ICON[k]
        d.ellipse([x, y, x + 18, y + 18], fill=c)
        d.text((x + 26, y - 1), t, fill=(220, 210, 195), font=font(17))
        x += 60 + d.textlength(t, font=font(17))
        if x > Wd - 260:
            x, y = 40, y + 40
    return im

imgs = {k: draw(k, 34 if k in ("baja", "alta", "atico") else (13 if k == "exterior" else 24)) for k in PLANTAS}
for k, im in imgs.items():
    im.save(os.path.join(OUT, f"plano_{k}.png"))
print("PLANO OK", {k: im.size for k, im in imgs.items()})
