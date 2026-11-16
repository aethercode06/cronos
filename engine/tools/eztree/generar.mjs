// Genera árboles realistas con Ez-Tree (github.com/dgreenheck/ez-tree, MIT) y guarda su geometría en JSON
// (ramas y hojas por separado) para pasarlos a GLB en Blender. Uso: node generar.mjs <salida>
import { Tree } from '@dgreenheck/ez-tree';
import fs from 'fs';
const OUT = process.argv[2] || 'out';
fs.mkdirSync(OUT, { recursive: true });
const PEDIDOS = [
  ['pino_grande_1', 'Pine Large', 101, {}], ['pino_grande_2', 'Pine Large', 202, {}], ['pino_grande_3', 'Pine Large', 303, {}],
  ['pino_mediano_1', 'Pine Medium', 404, {}], ['pino_mediano_2', 'Pine Medium', 505, {}], ['pino_joven', 'Pine Small', 606, {}],
  ['muerto_roble', 'Oak Large', 707, { leaves: { count: 0 } }], ['muerto_fresno', 'Ash Large', 808, { leaves: { count: 0 } }],
  ['muerto_roble_2', 'Oak Medium', 909, { leaves: { count: 0 } }],
  ['arbusto_1', 'Bush 1', 111, {}], ['arbusto_2', 'Bush 2', 222, {}],
];
function dump(mesh) {
  const g = mesh.geometry;
  if (!g || !g.attributes.position) return null;
  const a = (n) => (g.attributes[n] ? Array.from(g.attributes[n].array, (v) => Math.round(v * 10000) / 10000) : []);
  return { pos: a('position'), nor: a('normal'), uv: a('uv'), idx: g.index ? Array.from(g.index.array) : [] };
}
const info = {};
for (const [nombre, preset, seed, extra] of PEDIDOS) {
  const t = new Tree();
  t.loadPreset(preset);
  t.options.seed = seed;
  for (const k in extra) Object.assign(t.options[k], extra[k]);
  t.generate();
  const d = { preset, seed, bark: t.options.bark, leaves: t.options.leaves, ramas: dump(t.branchesMesh), hojas: t.options.leaves.count > 0 ? dump(t.leavesMesh) : null };
  fs.writeFileSync(`${OUT}/${nombre}.json`, JSON.stringify(d));
  info[nombre] = { preset, seed, vr: d.ramas.pos.length / 3, vh: d.hojas ? d.hojas.pos.length / 3 : 0, bark: t.options.bark.type, hoja: t.options.leaves.type };
  console.log(nombre, JSON.stringify(info[nombre]));
}
fs.writeFileSync(`${OUT}/info.json`, JSON.stringify(info, null, 1));
