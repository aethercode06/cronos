import bpy, sys
bpy.ops.wm.open_mainfile(filepath=sys.argv[-1])
for m in bpy.data.materials:
    if not m.use_nodes: continue
    print("MAT", m.name)
    for n in m.node_tree.nodes:
        if n.type=='TEX_IMAGE' and n.image: print("   ", n.name, n.image.name, n.image.size[:], n.image.filepath, [l.to_socket.name+"@"+l.to_node.name for l in n.outputs[0].links])
        elif n.type not in ('TEX_COORD','MAPPING'): print("   ", n.type, n.name)
for o in bpy.data.objects:
    if o.name.endswith('_export'): print("MOD", o.name, [(md.type, md.name) for md in o.modifiers], list(o.vertex_groups.keys())[:5], len(o.vertex_groups))
