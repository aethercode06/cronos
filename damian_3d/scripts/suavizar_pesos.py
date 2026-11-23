"""Suaviza los pesos de piel en hombros, codos y muñecas (menos pliegues al doblar)."""
import bpy, sys
bpy.ops.wm.open_mainfile(filepath="/home/claude/damian/out/damian_mixamo.blend")
body = bpy.data.objects["cuerpo"]
grupos = [g.name for g in body.vertex_groups if any(k in g.name for k in ("Arm", "ForeArm", "Shoulder", "Hand\x00", "Spine2"))] + \
         [g.name for g in body.vertex_groups if g.name in ("mixamorig:RightHand", "mixamorig:LeftHand")]
bpy.context.view_layer.objects.active = body; body.select_set(True)
bpy.ops.object.mode_set(mode='WEIGHT_PAINT')
for g in grupos:
    body.vertex_groups.active_index = body.vertex_groups[g].index
    bpy.ops.object.vertex_group_smooth(group_select_mode='ACTIVE', factor=0.6, repeat=int(sys.argv[-1]) if sys.argv[-1].isdigit() else 6, expand=0.15)
bpy.ops.object.vertex_group_normalize_all(group_select_mode='ALL', lock_active=False)
bpy.ops.object.mode_set(mode='OBJECT')
print("SUAVIZADOS", grupos)
bpy.ops.wm.save_as_mainfile(filepath="/home/claude/damian/out/damian_mixamo.blend")
