"""Suaviza la forma de la piel alrededor de los codos (el brazo engordado hacía un escalón con el antebrazo)."""
import bpy, bmesh, sys
bpy.ops.wm.open_mainfile(filepath="/home/claude/damian/out/damian_mixamo.blend")
body = bpy.data.objects["cuerpo"]; rig = bpy.data.objects["Damian_rig"]
codos = [rig.matrix_world @ rig.data.bones[f"mixamorig:{l}ForeArm"].head_local for l in ("Right", "Left")]
inv = body.matrix_world.inverted()
bm = bmesh.new(); bm.from_mesh(body.data)
R = float(sys.argv[-1]) if sys.argv[-1].replace('.', '').isdigit() else 0.12
for it in range(12):
    vs = [v for v in bm.verts if not v.is_boundary and any((body.matrix_world @ v.co - c).length < R for c in codos)]
    bmesh.ops.smooth_vert(bm, verts=vs, factor=0.5, use_axis_x=True, use_axis_y=True, use_axis_z=True)
bm.to_mesh(body.data); bm.free()
print("CODOS SUAVIZADOS")
bpy.ops.wm.save_as_mainfile(filepath="/home/claude/damian/out/damian_mixamo.blend")
