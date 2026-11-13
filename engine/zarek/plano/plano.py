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
    "titulo": "EXTERIOR · La mansión en medio del bosque", "w": 90, "h": 104,
    "zonas": [
        ("Bosque de pinos", "bosque", 0, 0, 90, 104),
        ("Terrenos de la mansión (jardines salvajes, muro de piedra)", "jardin", 20, 12, 50, 56),
        ("Jardín trasero", "jardin", 22, 14, 46, 14),
        ("Laberinto de setos", "bosque", 48, 15, 14, 11),
        ("Caseta del jardinero", "edificio", 24, 16, 5, 4),
        ("Estanque", "agua", 32, 17, 9, 5),
        ("MANSIÓN VICTORIANA", "edificio", 35, 30, 18, 12),
        ("Porche", "camino", 36, 42, 16, 2),
        ("Invernadero", "edificio", 57, 29, 8, 8),
        ("Cochera", "edificio", 57, 38, 8, 7),
        ("Salida del túnel", "edificio", 56, 46, 4, 2),
        ("Pozo (aljibe)", "agua", 29, 35, 3, 3),
        ("Huerto seco", "camino", 23, 40, 9, 6),
        ("Jardín delantero", "jardin", 22, 46, 46, 20),
        ("Fuente", "agua", 41, 51, 6, 4),
        ("Camino de entrada", "camino", 43, 44, 2, 24),
        ("Portón", "camino", 41, 68, 6, 1),
        ("Camino del bosque", "camino", 43, 69, 2, 8),
        ("Camino del bosque", "camino", 30, 76, 15, 2),
        ("Camino del bosque", "camino", 30, 77, 2, 11),
        ("Camino del bosque", "camino", 30, 87, 20, 2),
        ("Camino del bosque", "camino", 48, 88, 2, 16),
        ("Arroyo", "agua", 0, 82, 90, 2),
        ("Puente viejo", "camino", 29, 81, 4, 4),
        ("Sendero", "camino", 45, 77, 22, 2),
        ("Cabaña del cazador", "edificio", 66, 73, 8, 6),
        ("Claro del columpio", "camino", 9, 58, 6, 6),
        ("Sendero", "camino", 5, 60, 4, 2),
        ("Sendero", "camino", 5, 60, 2, 18),
        ("Sendero", "camino", 5, 76, 25, 2),
        ("Árbol de los cuervos", "camino", 76, 18, 6, 6),
        ("Sendero", "camino", 70, 20, 6, 2),
    ],
    "marcas": [("inicio", 49, 101, "INICIO: el coche averiado en la carretera"), ("sello", 61, 33, "Sello 4"),
               ("armario", 26.5, 18.5, ""), ("armario", 70, 76, ""), ("susto", 12, 63.5, "Columpio que se mueve solo"),
               ("susto", 79, 24.5, ""), ("susto", 33.5, 84.5, "Algo cruza el puente"),
               ("puerta", 44, 42, "Entrada principal"), ("puerta", 45, 30, "Puerta trasera"),
               ("tunel", 30.5, 36.5, ""), ("tunel", 58, 47, ""), ("nota", 70, 78, "Nota del cazador")],
},
"baja": {
    "titulo": "PLANTA BAJA", "w": 18, "h": 12,
    "zonas": [
        ("Pasillo principal", "pasillo", 0, 4, 18, 1),
        ("Biblioteca", "sala", 0, 0, 4, 4),
        ("Estudio del padre", "sala", 4, 0, 2, 4),
        ("Salón de baile", "sala", 6, 0, 6, 4),
        ("Sala de fumar y billar", "sala", 12, 0, 3, 4),
        ("Cuarto de servicio", "servicio", 15, 0, 3, 4),
        ("Salón con chimenea", "sala", 0, 5, 5, 4),
        ("Sala de las mañanas", "sala", 5, 5, 2, 4),
        ("Torre", "sala", 0, 9, 3, 3),
        ("Sala de música", "sala", 3, 9, 4, 3),
        ("Vestíbulo y gran escalera", "sala", 7, 5, 4, 7),
        ("Comedor formal", "sala", 11, 5, 4, 4),
        ("Guardarropa", "servicio", 11, 9, 2, 3),
        ("Antecocina", "servicio", 13, 9, 2, 3),
        ("Cocina", "servicio", 15, 5, 3, 4),
        ("Despensa", "servicio", 15, 9, 3, 3),
    ],
    "puertas": [("h", 9, 12), ("h", 9, 0), ("h", 2, 4), ("h", 5, 4), ("h", 9, 4), ("h", 13, 4), ("h", 16, 4),
                ("h", 2, 5), ("h", 6, 5), ("h", 8, 5), ("h", 12, 5), ("h", 16, 5),
                ("v", 5, 7), ("v", 7, 7), ("v", 3, 10), ("v", 7, 10), ("v", 11, 7), ("v", 11, 10), ("v", 13, 10),
                ("v", 15, 10), ("v", 4, 2), ("v", 15, 2), ("v", 6, 1)],
    "marcas": [("escalera", 9, 8.2, "Gran escalera"), ("escalera", 16.5, 6.8, "Servicio ↑"), ("escalera", 16.5, 10.8, "Sótano ↓"),
               ("escalera", 1.5, 10.5, ""), ("pasadizo", 5.0, 3.5, "Pasadizo secreto"),
               ("sello", 9, 1.5, "Sello 1"), ("piano", 7.5, 1.0, "Piano"), ("piano", 5.0, 10.5, ""),
               ("armario", 0.5, 2.0, ""), ("armario", 14.5, 2.0, ""), ("armario", 4.4, 8.6, ""), ("armario", 12.0, 11.5, ""),
               ("armario", 17.5, 2.5, ""), ("lampara", 2.5, 7.0, ""), ("lampara", 9.0, 2.0, ""), ("lampara", 13.0, 7.0, ""),
               ("lampara", 9.0, 6.0, ""), ("lampara", 2.0, 2.0, ""),
               ("radio", 4.0, 6.0, "Radio"), ("chimenea", 0.4, 6.5, "Chimenea"), ("chimenea", 2.0, 0.35, "Chimenea"),
               ("chimenea", 13.0, 8.65, "Chimenea"), ("chimenea", 9.0, 0.35, "")],
},
"alta": {
    "titulo": "PRIMER PISO", "w": 18, "h": 12,
    "zonas": [
        ("Pasillo", "pasillo", 0, 4, 18, 1),
        ("Dormitorio de los padres", "dormitorio", 0, 0, 4, 4),
        ("Tocador de la madre", "dormitorio", 4, 0, 2, 4),
        ("EPICENTRO · cuarto de Elena", "epicentro", 6, 0, 4, 4),
        ("Cuarto del hermano", "dormitorio", 10, 0, 3, 4),
        ("Cuarto de niños", "dormitorio", 13, 0, 3, 4),
        ("Baño", "servicio", 16, 0, 2, 4),
        ("Cuarto de huéspedes azul", "dormitorio", 0, 5, 3, 4),
        ("Sala de costura", "sala", 3, 5, 4, 4),
        ("Torre", "sala", 0, 9, 3, 3),
        ("Cuarto de la institutriz", "dormitorio", 3, 9, 4, 3),
        ("Galería de retratos", "sala", 7, 5, 4, 5),
        ("Balcón", "jardin", 7, 10, 4, 2),
        ("Cuarto de huéspedes", "dormitorio", 11, 5, 4, 4),
        ("Escalera de servicio", "servicio", 15, 5, 3, 4),
        ("Cuarto de lectura", "sala", 11, 9, 4, 3),
        ("Cuarto de plancha", "servicio", 15, 9, 3, 3),
    ],
    "puertas": [("h", 2, 4), ("h", 5, 4), ("h", 8, 4), ("h", 11, 4), ("h", 14, 4), ("h", 17, 4),
                ("h", 1, 5), ("h", 5, 5), ("h", 9, 5), ("h", 13, 5), ("h", 16, 5),
                ("v", 4, 2), ("v", 13, 2), ("h", 1, 9), ("h", 5, 9), ("h", 9, 10), ("h", 13, 9), ("h", 16, 9)],
    "marcas": [("escalera", 9, 6.2, "Gran escalera"), ("escalera", 16.5, 6.8, "Ático ↑"), ("escalera", 1.5, 10.5, ""),
               ("sello", 1.5, 1.5, "Sello 2"), ("circulo", 8, 2, ""),
               ("armario", 3.5, 3.5, ""), ("armario", 12.5, 0.5, ""), ("armario", 15.5, 3.5, ""), ("armario", 0.5, 8.0, ""),
               ("armario", 14.5, 8.5, ""), ("armario", 6.5, 11.5, ""), ("lampara", 5.0, 7.0, ""), ("lampara", 13.0, 7.0, ""),
               ("lampara", 9.0, 7.5, ""), ("lampara", 2.0, 2.0, ""), ("espejo", 5.0, 0.5, "Espejo"),
               ("caja", 14.5, 1.5, "Caja de música"), ("chimenea", 0.4, 2.0, "Chimenea")],
},
"atico": {
    "titulo": "ÁTICO Y MIRADOR DE LA TORRE", "w": 18, "h": 12,
    "zonas": [
        ("Ático (vigas, baúles, muñecos tapados)", "servicio", 3, 1, 15, 10),
        ("Rincón de Elena", "epicentro", 4, 2, 3, 2),
        ("Mirador de la torre", "sala", 0, 9, 3, 3),
    ],
    "puertas": [("v", 3, 10)],
    "marcas": [("escalera", 15.5, 7.5, "Escalera de servicio"), ("armario", 9, 10.5, ""), ("armario", 16.5, 2, ""),
               ("nota", 5.5, 3, "Diario de Elena (1974)"), ("escalera", 1.5, 10.5, "")],
},
"sotano": {
    "titulo": "SÓTANO Y TÚNELES", "w": 32, "h": 24,
    "zonas": [
        ("Pasillo del sótano", "sotano", 9, 6, 15, 2),
        ("Galería de servicio", "sotano", 11, 1, 6, 5),
        ("Archivo", "sotano", 9, 8, 5, 5),
        ("Sala de calderas", "sotano", 14, 8, 5, 5),
        ("Cava de vinos", "sotano", 19, 8, 5, 6),
        ("Túnel oeste", "tunel", 3, 6, 6, 2),
        ("Pozo (sale al jardín)", "agua", 0, 5, 3, 4),
        ("Túnel este", "tunel", 24, 6, 6, 2),
        ("Túnel este", "tunel", 28, 8, 2, 8),
        ("Salida a la cochera", "tunel", 27, 16, 4, 2),
        ("Túnel profundo", "tunel", 11, 13, 2, 4),
        ("Cámara de la roca madre", "roca", 7, 17, 10, 5),
    ],
    "puertas": [("h", 14, 6), ("h", 11, 8), ("h", 16, 8), ("h", 21, 8), ("v", 9, 6), ("v", 24, 6),
                ("h", 11, 13), ("h", 11, 17), ("v", 3, 6)],
    "marcas": [("escalera", 21.5, 11.2, "Despensa ↑"), ("pasadizo", 13, 2.5, "Pasadizo al estudio del padre"),
               ("sello", 20.5, 9.5, "Sello 3"), ("armario", 9.5, 12, ""), ("armario", 16.5, 1.5, ""), ("armario", 18, 12.5, ""),
               ("lampara", 16.5, 10.5, ""), ("roca", 12, 20, "Cerrada (próximas noches)"),
               ("tunel", 1.5, 6.5, ""), ("tunel", 29, 17, "")],
},
}

PLANTAS["baja"]["origen"] = [35, 30]; PLANTAS["baja"]["nivel"] = 0
PLANTAS["alta"]["origen"] = [35, 30]; PLANTAS["alta"]["nivel"] = 1
PLANTAS["atico"]["origen"] = [35, 30]; PLANTAS["atico"]["nivel"] = 2
PLANTAS["sotano"]["origen"] = [30, 30]; PLANTAS["sotano"]["nivel"] = -1
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
