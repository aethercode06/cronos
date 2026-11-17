"""Instala MPFB (extensión de Blender de MakeHuman) en el módulo bpy y copia los recursos CC0 a su carpeta de datos.
Uso: python instalar_mpfb.py <mpfb.zip> <carpeta_recursos>"""
import bpy, sys, os, shutil
zipf, assets = sys.argv[-2], sys.argv[-1]
bpy.ops.extensions.package_install_files(filepath=zipf, repo='user_default', enable_on_install=True)
ud = bpy.utils.extension_path_user("bl_ext.user_default.mpfb", create=True)
dst = os.path.join(ud, "data")
os.makedirs(dst, exist_ok=True)
for d in os.listdir(assets):
    s = os.path.join(assets, d)
    if os.path.isdir(s):
        shutil.copytree(s, os.path.join(dst, d), dirs_exist_ok=True)
bpy.ops.wm.save_userpref()
print("MPFB INSTALADO", ud, sorted(os.listdir(dst)))
