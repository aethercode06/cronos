import bpy, sys, os
bpy.ops.wm.open_mainfile(filepath=sys.argv[-2]); out=sys.argv[-1]; os.makedirs(out, exist_ok=True)
for im in bpy.data.images:
    if im.size[0] > 0 and im.packed_file:
        open(os.path.join(out, os.path.basename(im.filepath)), 'wb').write(im.packed_file.data); print("img", im.name)
