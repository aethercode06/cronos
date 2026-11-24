#!/usr/bin/env python3
"""Parche de La Sombra de Zarek: empaqueta TODO lo que ha cambiado desde el último APK publicado (código, escenas,
sonidos, modelos…) en un .pck pequeño y lo sube a la release «zarek-parche». El juego (zarek/arranque.gd) lo descarga
al abrirse y lo aplica: no hace falta instalar un APK nuevo para cada cambio.

Uso (desde la raíz del repo, con el proyecto ya importado y los cambios hechos):
    python3 engine/tools/parche.py            # crea y sube el parche
    python3 engine/tools/parche.py --solo-ver # solo dice qué entraría

Los parches son acumulativos (cada uno lleva todo lo cambiado desde el APK). Lo que un parche NO puede cambiar
(project.godot, export_presets.cfg, el propio arranque) necesita un APK nuevo: el script avisa.
"""
import json, os, re, subprocess, sys, tempfile, urllib.request

REPO = "aethercode06/cronos"
RAIZ = subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()
ENG = os.path.join(RAIZ, "engine")
NO_VAN = ("tests/", "tools/", "chronos/", "demo/", "assets/chronos/", "keys/", "branding/", ".godot/", "plantillas/",
          "publicar/", "idiomas_src/")
NECESITAN_APK = ("project.godot", "export_presets.cfg", "zarek/arranque.gd", "zarek/arranque.tscn")


def sh(*a, **k):
    return subprocess.run(a, check=True, text=True, capture_output=True, **k).stdout


def gh_asset(tag, nombre):
    try:
        ids = sh("gh", "api", f"repos/{REPO}/releases/tags/{tag}", "--jq", f'.assets[]|select(.name=="{nombre}")|.id').split()
    except subprocess.CalledProcessError:
        return None
    if not ids:
        return None
    return subprocess.run(["gh", "api", "-H", "Accept: application/octet-stream", f"repos/{REPO}/releases/assets/{ids[0]}"],
                          check=True, capture_output=True).stdout


def main():
    solo_ver = "--solo-ver" in sys.argv
    b = gh_asset("zarek", "base.json")
    if not b:
        sys.exit("No encuentro base.json en la release «zarek»: hace falta un APK nuevo con el sistema de parches.")
    base = json.loads(b)
    commit = base["commit"]
    # cambiado desde el commit del APK (incluye lo que aún no está en un commit) + archivos nuevos sin seguimiento
    cambios = sh("git", "diff", "--name-only", commit, "--", "engine/", cwd=RAIZ).split()
    cambios += sh("git", "ls-files", "--others", "--exclude-standard", "engine/", cwd=RAIZ).split()
    archivos, avisos = set(), []
    for c in cambios:
        rel = c[len("engine/"):]
        if rel in NECESITAN_APK:
            avisos.append(rel)
            continue
        if rel.startswith(NO_VAN) or rel.endswith((".md", ".py", ".blend", ".txt")) and not rel.startswith("zarek/sonidos"):
            continue
        if rel.endswith(".import"):
            rel = rel[:-len(".import")]
        if rel.endswith(".uid"):
            rel = rel[:-len(".uid")]
        if not os.path.exists(os.path.join(ENG, rel)):
            continue  # borrado: un parche no puede borrar (no pasa nada si queda el viejo)
        archivos.add("res://" + rel)
    archivos = sorted(archivos)
    print(f"APK base n.º {base['base']} (commit {commit[:8]}) · {len(archivos)} archivos cambiados")
    for a in archivos:
        print("  ", a)
    if avisos:
        print("AVISO: estos cambios necesitan un APK nuevo (el parche no los lleva):", ", ".join(avisos))
    if solo_ver or not archivos:
        return
    # versión del parche
    v = 1
    pj = gh_asset("zarek-parche", "parche.json")
    if pj:
        viejo = json.loads(pj)
        if str(viejo.get("base")) == str(base["base"]):
            v = int(viejo.get("version", 0)) + 1
    # preset temporal «Parche Zarek» copiado del de Android (mismas texturas, mismas opciones) con solo esos archivos
    ep = os.path.join(ENG, "export_presets.cfg")
    original = open(ep).read()
    try:
        i = original.index('name="Android Zarek"')
        ini = original.rfind("[preset.", 0, i)
        fin = original.find("[preset.", original.index("[preset.", i) + 1)  # salta el bloque .options
        seg = original[ini:fin if fin > 0 else len(original)]
        n = max(int(x) for x in re.findall(r"\[preset\.(\d+)\]", original)) + 1
        seg = re.sub(r"\[preset\.\d+\]", f"[preset.{n}]", seg, count=1)
        seg = re.sub(r"\[preset\.\d+\.options\]", f"[preset.{n}.options]", seg, count=1)
        seg = seg.replace('name="Android Zarek"', 'name="Parche Zarek"')
        lista = ", ".join(f'"{a}"' for a in archivos)
        seg = re.sub(r'export_filter="[^"]*"', f'export_filter="resources"\nexport_files=PackedStringArray({lista})', seg, count=1)
        seg = re.sub(r'include_filter="[^"]*"', 'include_filter=""', seg, count=1)
        open(ep, "w").write(original + "\n" + seg)
        os.makedirs(os.path.join(RAIZ, "build"), exist_ok=True)
        salida = os.path.join(RAIZ, "build", f"parche_{v}.pck")
        if os.path.exists(salida):
            os.remove(salida)
        r = subprocess.run(["godot", "--headless", "--path", ENG, "--export-pack", "Parche Zarek", salida],
                           capture_output=True, text=True, timeout=1200)
        if not os.path.exists(salida):
            print(r.stdout[-3000:], r.stderr[-2000:])
            sys.exit("No se pudo exportar el parche.")
    finally:
        open(ep, "w").write(original)
    tam = os.path.getsize(salida)
    print(f"Parche {v}: {tam / 1e6:.1f} MB")
    url = f"https://github.com/{REPO}/releases/download/zarek-parche/parche_{v}.pck"
    info = {"base": str(base["base"]), "version": v, "url": url, "tam": tam, "commit": sh("git", "rev-parse", "HEAD", cwd=RAIZ).strip()}
    pj_path = os.path.join(RAIZ, "build", "parche.json")
    json.dump(info, open(pj_path, "w"))
    if subprocess.run(["gh", "release", "view", "zarek-parche", "-R", REPO], capture_output=True).returncode != 0:
        sh("gh", "release", "create", "zarek-parche", "-R", REPO, "--title", "La Sombra de Zarek · actualizaciones",
           "--notes", "Actualizaciones pequeñas que el juego descarga solo al abrirse. No hace falta bajar nada de aquí.",
           "--latest=false")
    sh("gh", "release", "upload", "zarek-parche", salida, "-R", REPO, "--clobber")
    sh("gh", "release", "upload", "zarek-parche", pj_path, "-R", REPO, "--clobber")  # al final: así nunca apunta a un .pck a medio subir
    # borrar parches viejos
    for nombre in sh("gh", "api", f"repos/{REPO}/releases/tags/zarek-parche", "--jq", ".assets[].name").split():
        if nombre.startswith("parche_") and nombre != f"parche_{v}.pck":
            subprocess.run(["gh", "release", "delete-asset", "zarek-parche", nombre, "-R", REPO, "-y"], capture_output=True)
    print(f"Subido: parche {v} para el APK {base['base']}. Basta con cerrar y abrir el juego.")


if __name__ == "__main__":
    main()
