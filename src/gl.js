// =====================================================================
//  POSTPROCESADO WEBGL: iluminación dinámica, bloom, rayos de luz,
//  distorsión por calor, gradación de color y cámara subpíxel
// =====================================================================
const LOOK = [
  { amb: '#a8a395', sun: [0.84, 0.9], rays: 0.32, thr: 0.78, bloom: 0.45, sat: 1.15, con: 1.06, gain: [1.04, 1.0, 0.94], lift: [0.0, 0.01, 0.02], haze: 0, vig: 0.32, ca: 0.6, pl: 0.08, plc: 'rgba(255,240,210,1)', fog: '200,255,230', fogA: 0.18 },
  { amb: '#6a6880', sun: [0.4, 0.12], rays: 0.18, thr: 0.62, bloom: 0.8, sat: 1.05, con: 1.1, gain: [1.0, 0.96, 1.04], lift: [0.01, 0.0, 0.03], haze: 0, vig: 0.55, ca: 0.7, pl: 0.22, plc: 'rgba(255,200,150,1)', fog: '120,130,170', fogA: 0.24 },
  { amb: '#907763', sun: [0.5, 0.15], rays: 0.12, thr: 0.72, bloom: 0.7, sat: 1.15, con: 1.08, gain: [1.08, 0.97, 0.9], lift: [0.02, 0.0, 0.0], haze: 1.1, vig: 0.42, ca: 0.6, pl: 0.14, plc: 'rgba(255,200,150,1)', fog: '255,120,60', fogA: 0.16 },
  { amb: '#908095', sun: [0.62, 0.86], rays: 0.22, thr: 0.88, bloom: 0.4, sat: 1.12, con: 1.06, gain: [1.05, 0.97, 1.0], lift: [0.02, 0.0, 0.02], haze: 0, vig: 0.4, ca: 0.6, pl: 0.12, plc: 'rgba(255,220,200,1)', fog: '255,170,190', fogA: 0.2 },
  { amb: '#6e6497', sun: [0.58, 0.82], rays: 0.32, thr: 0.6, bloom: 0.85, sat: 1.12, con: 1.08, gain: [1.0, 0.92, 1.08], lift: [0.02, 0.0, 0.04], haze: 0, vig: 0.6, ca: 0.8, pl: 0.26, plc: 'rgba(220,200,255,1)', fog: '160,110,220', fogA: 0.28 },
  { amb: '#7b8da8', sun: [0.25, 0.92], rays: 0.28, thr: 0.86, bloom: 0.45, sat: 0.98, con: 1.05, gain: [0.94, 1.0, 1.1], lift: [0.0, 0.01, 0.04], haze: 0, vig: 0.45, ca: 0.6, pl: 0.18, plc: 'rgba(200,235,255,1)', fog: '200,230,255', fogA: 0.24 },
  { amb: '#624642', sun: [0.5, 0.1], rays: 0.1, thr: 0.68, bloom: 0.8, sat: 1.15, con: 1.1, gain: [1.1, 0.95, 0.88], lift: [0.03, 0.0, 0.0], haze: 0.8, vig: 0.6, ca: 0.8, pl: 0.22, plc: 'rgba(255,190,140,1)', fog: '255,80,40', fogA: 0.18 },
  { amb: '#70649e', sun: [0.72, 0.8], rays: 0.28, thr: 0.6, bloom: 1.0, sat: 1.2, con: 1.08, gain: [1.0, 0.96, 1.08], lift: [0.02, 0.0, 0.04], haze: 0, vig: 0.45, ca: 1.3, pl: 0.2, plc: 'rgba(230,200,255,1)', fog: '170,120,255', fogA: 0.2 },
  { amb: '#6089a5', sun: [0.4, 0.95], rays: 0.42, thr: 0.7, bloom: 0.8, sat: 1.15, con: 1.06, gain: [0.92, 1.02, 1.1], lift: [0.0, 0.02, 0.05], haze: 0.5, vig: 0.5, ca: 0.8, pl: 0.22, plc: 'rgba(170,255,255,1)', fog: '120,220,255', fogA: 0.24 },
  { amb: '#a89077', sun: [0.7, 0.9], rays: 0.3, thr: 0.8, bloom: 0.55, sat: 1.12, con: 1.07, gain: [1.08, 1.0, 0.9], lift: [0.03, 0.01, 0.0], haze: 0.9, vig: 0.4, ca: 0.6, pl: 0.1, plc: 'rgba(255,230,190,1)', fog: '255,210,140', fogA: 0.16 },
  { amb: '#97a1ba', sun: [0.55, 0.92], rays: 0.3, thr: 0.9, bloom: 0.4, sat: 1.1, con: 1.1, gain: [1.0, 0.99, 1.04], lift: [0.0, 0.01, 0.03], haze: 0, vig: 0.3, ca: 0.5, pl: 0.1, plc: 'rgba(255,250,230,1)', fog: '255,255,255', fogA: 0.14 },
  { amb: '#5d487e', sun: [0.5, 0.5], rays: 0.2, thr: 0.6, bloom: 1.1, sat: 1.22, con: 1.1, gain: [1.04, 0.94, 1.1], lift: [0.03, 0.0, 0.05], haze: 0.3, vig: 0.55, ca: 1.4, pl: 0.24, plc: 'rgba(255,190,255,1)', fog: '220,90,255', fogA: 0.22 }
  ,{ amb: '#a09ca6', sun: [0.66, 0.22], rays: 0.16, thr: 0.7, bloom: 0.7, sat: 1.08, con: 1.1, gain: [0.98, 1.0, 0.98], lift: [0.01, 0.02, 0.02], haze: 0.3, vig: 0.55, ca: 0.6, pl: 0.2, plc: 'rgba(200,255,190,1)', fog: '110,130,120', fogA: 0.2 },
  { amb: '#666e88', sun: [0.5, 0.1], rays: 0.2, thr: 0.65, bloom: 0.85, sat: 1.0, con: 1.1, gain: [0.95, 0.98, 1.08], lift: [0.0, 0.01, 0.04], haze: 0, vig: 0.58, ca: 0.7, pl: 0.22, plc: 'rgba(170,200,255,1)', fog: '120,140,200', fogA: 0.24 },
  { amb: '#8a7cb0', sun: [0.5, 0.2], rays: 0.12, thr: 0.72, bloom: 0.55, sat: 0.98, con: 1.08, gain: [1.0, 0.96, 1.05], lift: [0.02, 0.0, 0.05], haze: 0, vig: 0.55, ca: 0.8, pl: 0.24, plc: 'rgba(220,180,255,1)', fog: '100,70,150', fogA: 0.2 },
  { amb: '#6c7672', sun: [0.62, 0.2], rays: 0.18, thr: 0.7, bloom: 0.6, sat: 0.92, con: 1.1, gain: [0.97, 1.0, 1.0], lift: [0.01, 0.02, 0.02], haze: 0, vig: 0.58, ca: 0.6, pl: 0.22, plc: 'rgba(200,255,230,1)', fog: '150,190,175', fogA: 0.26 },
  { amb: '#86705a', sun: [0.5, 0.15], rays: 0.2, thr: 0.68, bloom: 0.8, sat: 1.08, con: 1.08, gain: [1.08, 0.99, 0.88], lift: [0.03, 0.01, 0.0], haze: 0.2, vig: 0.52, ca: 0.6, pl: 0.22, plc: 'rgba(255,210,150,1)', fog: '255,190,110', fogA: 0.18 },
  { amb: '#555b7a', sun: [0.7, 0.15], rays: 0.1, thr: 0.7, bloom: 0.6, sat: 0.95, con: 1.12, gain: [0.94, 0.98, 1.1], lift: [0.0, 0.01, 0.04], haze: 0, vig: 0.6, ca: 0.7, pl: 0.22, plc: 'rgba(190,210,255,1)', fog: '70,80,130', fogA: 0.22 }
];
const lightBuf = document.createElement('canvas');
const lx = lightBuf.getContext('2d');
let GL = null, glOK = false, camZoom = 1, zoomKick = 0, glQ = 2, perfT = 0, perfN = 0, perfSum = 0;
// Calidad adaptativa: si el dispositivo no mantiene la fluidez, se reducen los efectos
function perfSample(dt) {
  if (!glOK || state !== 'playing') return;
  perfSum += dt; perfN++; perfT += dt;
  if (perfT > 3) { const avg = perfSum / perfN; perfT = perfSum = perfN = 0;
    if (avg > 0.026 && glQ > 0) { glQ--; if (glQ === 0) { glOK = false; document.getElementById('gl').style.display = 'none'; } } }
}
function lightAt(x, y, r, color, a) {
  if (!glOK || r <= 0) return;
  lx.globalCompositeOperation = 'lighter'; lx.globalAlpha = clamp(a === undefined ? 1 : a, 0, 1);
  lx.drawImage(glowSpr(color), Math.round(x - r), Math.round(y - r), Math.round(r * 2), Math.round(r * 2));
  lx.globalAlpha = 1; lx.globalCompositeOperation = 'source-over';
}
function zoomPunch(z) { zoomKick = Math.max(zoomKick, z); }

const VS = `attribute vec2 a;varying vec2 u;void main(){u=a*0.5+0.5;gl_Position=vec4(a,0.,1.);}`;
const FS_COMMON = `precision mediump float;varying vec2 u;
uniform sampler2D S,Lt;uniform vec2 bs,vs,off;uniform float zm,hz,tm,qz;
vec2 bufUV(vec2 uv,bool snap){vec2 sp=(uv-0.5)/zm+0.5;sp*=vs;vec2 p=vec2(sp.x,vs.y-sp.y)+off;
 if(hz>0.){p.x+=sin(p.y*0.12+tm*3.)*hz*0.8+sin(p.y*0.31-tm*5.)*hz*0.4;}
 if(snap)p=(floor(p*qz)+0.5)/qz;return vec2(p.x/bs.x,1.-p.y/bs.y);}
`;
const FS_BRIGHT = FS_COMMON + `uniform float thr;void main(){vec2 b=bufUV(u,false);vec3 c=texture2D(S,b).rgb*min(texture2D(Lt,b).rgb*2.,vec3(1.32));
 float l=max(max(c.r,c.g),c.b);gl_FragColor=vec4(c*smoothstep(thr,thr+0.35,l),1.);}`;
const FS_BLUR = `precision mediump float;varying vec2 u;uniform sampler2D T;uniform vec2 d;void main(){
 vec3 c=texture2D(T,u).rgb*0.227;c+=(texture2D(T,u+d*1.385).rgb+texture2D(T,u-d*1.385).rgb)*0.316;
 c+=(texture2D(T,u+d*3.231).rgb+texture2D(T,u-d*3.231).rgb)*0.07;gl_FragColor=vec4(c,1.);}`;
const FS_RAYS = `precision mediump float;varying vec2 u;uniform sampler2D T;uniform vec2 sun;void main(){
 vec2 dl=(u-sun)/28.;vec2 p=u;float w=1.;vec3 c=vec3(0.);for(int i=0;i<28;i++){p-=dl;c+=texture2D(T,p).rgb*w;w*=0.93;}
 gl_FragColor=vec4(c/10.,1.);}`;
const FS_FINAL = FS_COMMON + `uniform sampler2D B1,B2,R;uniform float bloom,rays,sat,con,vig,ca,ex;uniform vec3 gain,lift;
float h(vec2 p){return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453);}
void main(){vec2 b=bufUV(u,true);vec2 d=u-0.5;float e=dot(d,d);
 vec2 cao=d*ca*e*6./bs;
 vec3 sc=vec3(texture2D(S,b+cao).r,texture2D(S,b).g,texture2D(S,b-cao).b);
 vec3 L=min(texture2D(Lt,bufUV(u,false)).rgb*2.,vec3(1.32));
 vec3 c=sc*L*ex;
 vec2 zu=(u-0.5)/zm+0.5;
 c+=texture2D(B1,u).rgb*bloom+texture2D(B2,u).rgb*bloom*0.9+texture2D(R,u).rgb*rays;
 c=c*gain+lift;
 float l=dot(c,vec3(0.299,0.587,0.114));c=mix(vec3(l),c,sat);
 c=(c-0.5)*con+0.5;
 c=mix(c,1.-exp(-c*1.25),smoothstep(0.75,1.6,c));
 c*=1.-vig*e*1.6;
 c+=(h(gl_FragCoord.xy+tm)-0.5)/180.;
 gl_FragColor=vec4(clamp(c,0.,1.),1.);}`;

function mkProg(fs) {
  const g = GL, sh = (t, s) => { const o = g.createShader(t); g.shaderSource(o, s); g.compileShader(o); if (!g.getShaderParameter(o, g.COMPILE_STATUS)) throw new Error(g.getShaderInfoLog(o)); return o; };
  const p = g.createProgram(); g.attachShader(p, sh(g.VERTEX_SHADER, VS)); g.attachShader(p, sh(g.FRAGMENT_SHADER, fs));
  g.bindAttribLocation(p, 0, 'a'); g.linkProgram(p);
  if (!g.getProgramParameter(p, g.LINK_STATUS)) throw new Error(g.getProgramInfoLog(p));
  const U = {}; const n = g.getProgramParameter(p, g.ACTIVE_UNIFORMS);
  for (let i = 0; i < n; i++) { const a = g.getActiveUniform(p, i); U[a.name] = g.getUniformLocation(p, a.name); }
  return { p, U };
}
function mkTex(filter) {
  const g = GL, t = g.createTexture(); g.bindTexture(g.TEXTURE_2D, t);
  g.texParameteri(g.TEXTURE_2D, g.TEXTURE_MIN_FILTER, filter); g.texParameteri(g.TEXTURE_2D, g.TEXTURE_MAG_FILTER, filter);
  g.texParameteri(g.TEXTURE_2D, g.TEXTURE_WRAP_S, g.CLAMP_TO_EDGE); g.texParameteri(g.TEXTURE_2D, g.TEXTURE_WRAP_T, g.CLAMP_TO_EDGE);
  return t;
}
function mkFBO(w, h) {
  const g = GL, t = mkTex(g.LINEAR); g.texImage2D(g.TEXTURE_2D, 0, g.RGBA, w, h, 0, g.RGBA, g.UNSIGNED_BYTE, null);
  const f = g.createFramebuffer(); g.bindFramebuffer(g.FRAMEBUFFER, f); g.framebufferTexture2D(g.FRAMEBUFFER, g.COLOR_ATTACHMENT0, g.TEXTURE_2D, t, 0);
  g.bindFramebuffer(g.FRAMEBUFFER, null); return { f, t, w, h };
}
let PG = {}, TX = {}, FB = {}, fbFor = '';
function initGL() {
  try {
    const glc = document.getElementById('gl');
    glc.width = W * RES; glc.height = H * RES;
    GL = glc.getContext('webgl', { alpha: false, antialias: false, preserveDrawingBuffer: false, powerPreference: 'high-performance' });
    if (!GL) return false;
    const g = GL;
    const vb = g.createBuffer(); g.bindBuffer(g.ARRAY_BUFFER, vb); g.bufferData(g.ARRAY_BUFFER, new Float32Array([-1, -1, 3, -1, -1, 3]), g.STATIC_DRAW);
    g.enableVertexAttribArray(0); g.vertexAttribPointer(0, 2, g.FLOAT, false, 0, 0);
    PG.bright = mkProg(FS_BRIGHT); PG.blur = mkProg(FS_BLUR); PG.rays = mkProg(FS_RAYS); PG.fin = mkProg(FS_FINAL);
    TX.scene = mkTex(g.NEAREST); TX.light = mkTex(g.LINEAR);
    g.pixelStorei(g.UNPACK_FLIP_Y_WEBGL, true);
    glOK = true; return true;
  } catch (e) { console.warn('WebGL no disponible', e); glOK = false; return false; }
}
function ensureFBO() {
  const id = VW + 'x' + VH; if (fbFor === id) return; fbFor = id;
  const hw = Math.ceil(VW / 2), hh = Math.ceil(VH / 2), qw = Math.ceil(VW / 4), qh = Math.ceil(VH / 4);
  FB.a = mkFBO(hw, hh); FB.b = mkFBO(hw, hh); FB.r = mkFBO(hw, hh); FB.c = mkFBO(qw, qh); FB.d = mkFBO(qw, qh);
}
function pass(prog, target, setup) {
  const g = GL; g.useProgram(prog.p);
  g.bindFramebuffer(g.FRAMEBUFFER, target ? target.f : null);
  g.viewport(0, 0, target ? target.w : g.canvas.width, target ? target.h : g.canvas.height);
  setup(prog.U); g.drawArrays(g.TRIANGLES, 0, 3);
}
function bindT(unit, tex, loc) { const g = GL; g.activeTexture(g.TEXTURE0 + unit); g.bindTexture(g.TEXTURE_2D, tex); g.uniform1i(loc, unit); }
function glPresent(look, ox, oy) {
  const g = GL; ensureFBO();
  g.activeTexture(g.TEXTURE0); g.bindTexture(g.TEXTURE_2D, TX.scene); g.texImage2D(g.TEXTURE_2D, 0, g.RGBA, g.RGBA, g.UNSIGNED_BYTE, buf);
  g.bindTexture(g.TEXTURE_2D, TX.light); g.texImage2D(g.TEXTURE_2D, 0, g.RGBA, g.RGBA, g.UNSIGNED_BYTE, lightBuf);
  const common = U => { g.uniform2f(U.bs, buf.width / QR, buf.height / QR); g.uniform1f(U.qz, QR); g.uniform2f(U.vs, VW, VH); g.uniform2f(U.off, ox, oy); g.uniform1f(U.zm, camZoom); g.uniform1f(U.hz, look.haze); g.uniform1f(U.tm, time % 1000); };
  pass(PG.bright, FB.a, U => { common(U); bindT(0, TX.scene, U.S); bindT(1, TX.light, U.Lt); g.uniform1f(U.thr, look.thr); });
  pass(PG.blur, FB.b, U => { bindT(0, FB.a.t, U.T); g.uniform2f(U.d, 1 / FB.a.w, 0); });
  pass(PG.blur, FB.a, U => { bindT(0, FB.b.t, U.T); g.uniform2f(U.d, 0, 1 / FB.a.h); });
  if (glQ > 1) {
    pass(PG.blur, FB.c, U => { bindT(0, FB.a.t, U.T); g.uniform2f(U.d, 2 / FB.a.w, 0); });
    pass(PG.blur, FB.d, U => { bindT(0, FB.c.t, U.T); g.uniform2f(U.d, 0, 1 / FB.c.h); });
    pass(PG.blur, FB.c, U => { bindT(0, FB.d.t, U.T); g.uniform2f(U.d, 1.5 / FB.c.w, 0); });
    pass(PG.blur, FB.d, U => { bindT(0, FB.c.t, U.T); g.uniform2f(U.d, 0, 1.5 / FB.c.h); });
  }
  if (look.rays > 0 && glQ > 1) pass(PG.rays, FB.r, U => { bindT(0, FB.a.t, U.T); g.uniform2f(U.sun, look.sun[0], look.sun[1]); });
  pass(PG.fin, null, U => {
    common(U); bindT(0, TX.scene, U.S); bindT(1, TX.light, U.Lt); bindT(2, FB.a.t, U.B1); bindT(3, FB.d.t, U.B2); bindT(4, FB.r.t, U.R);
    g.uniform1f(U.bloom, look.bloom); g.uniform1f(U.rays, glQ > 1 ? look.rays : 0); g.uniform1f(U.sat, look.sat); g.uniform1f(U.con, look.con);
    g.uniform1f(U.vig, look.vig); g.uniform1f(U.ca, look.ca); g.uniform1f(U.ex, 1.0);
    g.uniform3f(U.gain, look.gain[0], look.gain[1], look.gain[2]); g.uniform3f(U.lift, look.lift[0], look.lift[1], look.lift[2]);
  });
  if (look.rays <= 0) { g.bindFramebuffer(g.FRAMEBUFFER, FB.r.f); g.viewport(0, 0, FB.r.w, FB.r.h); g.clearColor(0, 0, 0, 1); g.clear(g.COLOR_BUFFER_BIT); g.bindFramebuffer(g.FRAMEBUFFER, null); }
}
