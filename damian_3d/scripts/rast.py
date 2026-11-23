"""Rasteriza la malla en espacio UV: devuelve por texel la posición 3D y la normal (para pintar por zonas del cuerpo)."""
import numpy as np

def rasterizar(me, mw, size, mat_index=None):
    me.calc_loop_triangles()
    uvl = me.uv_layers.active.data
    co = np.array([mw @ v.co for v in me.vertices], dtype=np.float32)
    nor = np.array([(mw.to_3x3() @ v.normal).normalized() for v in me.vertices], dtype=np.float32)
    P = np.zeros((size, size, 3), np.float32); N = np.zeros((size, size, 3), np.float32); M = np.zeros((size, size), bool)
    for t in me.loop_triangles:
        if mat_index is not None and t.material_index != mat_index:
            continue
        uv = np.array([uvl[l].uv for l in t.loops], dtype=np.float32) * size
        uv[:, 1] = size - uv[:, 1]
        vi = list(t.vertices)
        x0, y0 = np.floor(uv.min(0)).astype(int); x1, y1 = np.ceil(uv.max(0)).astype(int)
        x0 = max(x0, 0); y0 = max(y0, 0); x1 = min(x1, size - 1); y1 = min(y1, size - 1)
        if x1 < x0 or y1 < y0:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        (ax, ay), (bx, by), (cx, cy) = uv
        d = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(d) < 1e-9:
            continue
        w0 = ((by - cy) * (xs - cx) + (cx - bx) * (ys - cy)) / d
        w1 = ((cy - ay) * (xs - cx) + (ax - cx) * (ys - cy)) / d
        w2 = 1 - w0 - w1
        ins = (w0 >= -0.02) & (w1 >= -0.02) & (w2 >= -0.02)
        if not ins.any():
            continue
        yy = ys[ins].astype(int); xx = xs[ins].astype(int)
        W = np.stack([w0[ins], w1[ins], w2[ins]], 1)
        P[yy, xx] = W @ co[vi]; N[yy, xx] = W @ nor[vi]; M[yy, xx] = True
    return P, N, M

def _valor(P, f, semilla):
    """ruido de valor 3D con interpolación suave (sin rayas)"""
    rng = np.random.default_rng(semilla)
    T = rng.random(256 ** 1 * 4096).astype(np.float32)
    q = P * f
    i0 = np.floor(q).astype(np.int64); t = q - i0
    t = t * t * (3 - 2 * t)
    def h(ix, iy, iz):
        return T[((ix * 73856093) ^ (iy * 19349663) ^ (iz * 83492791)) % T.size]
    x0, y0, z0 = i0[..., 0], i0[..., 1], i0[..., 2]
    r = 0
    for dx in (0, 1):
        wx = t[..., 0] if dx else 1 - t[..., 0]
        for dy in (0, 1):
            wy = t[..., 1] if dy else 1 - t[..., 1]
            for dz in (0, 1):
                wz = t[..., 2] if dz else 1 - t[..., 2]
                r = r + wx * wy * wz * h(x0 + dx, y0 + dy, z0 + dz)
    return r

def ruido(P, escala, semilla=0):
    """fBm de ruido de valor, 0..1"""
    r = np.zeros(P.shape[:-1], np.float32); a = 1.0; tot = 0
    for k in range(5):
        r += _valor(P, escala * (2.0 ** k), semilla + k) * a; tot += a; a *= 0.5
    r /= tot
    lo, hi = np.percentile(r, 1), np.percentile(r, 99)
    return np.clip((r - lo) / max(hi - lo, 1e-6), 0, 1)

def sangre(P, M, region, n, rng, r_min=0.012, r_max=0.04, gotas=True):
    """manchas de sangre realistas en 3D: mancha con borde irregular, salpicaduras alrededor y chorretones
    hacia abajo. region: máscara (bool) donde pueden caer los centros. Devuelve 0..1 por texel."""
    from scipy.spatial import cKDTree
    idx = np.argwhere(M)
    pts = P[M]
    kd = cKDTree(pts)
    out = np.zeros(M.shape, np.float32)
    cand = np.argwhere(region & M)
    if len(cand) == 0: return out
    nz = ruido(P, 90, int(rng.integers(1000)))
    for k in range(n):
        yy, xx = cand[rng.integers(len(cand))]
        c = P[yy, xx]; r = rng.uniform(r_min, r_max)
        # mancha principal
        ii = kd.query_ball_point(c, r * 1.6)
        if ii:
            q = idx[ii]; d = np.linalg.norm(pts[ii] - c, axis=1)
            borde = r * (0.65 + 0.7 * nz[q[:, 0], q[:, 1]])
            v = np.clip((borde - d) / (r * 0.15), 0, 1)
            out[q[:, 0], q[:, 1]] = np.maximum(out[q[:, 0], q[:, 1]], v)
        # salpicaduras
        if gotas:
            for g in range(int(rng.integers(6, 20))):
                dd = rng.normal(size=3); dd /= np.linalg.norm(dd)
                cg = c + dd * rng.uniform(1.2, 3.5) * r; rg = rng.uniform(0.0015, 0.005)
                jj = kd.query_ball_point(cg, rg * 2.5)
                if jj:
                    q = idx[jj]; d = np.linalg.norm(pts[jj] - cg, axis=1)
                    out[q[:, 0], q[:, 1]] = np.maximum(out[q[:, 0], q[:, 1]], np.clip((rg - d) / (rg * 0.4), 0, 1))
        # chorretones (la sangre cae)
        for t in range(int(rng.integers(0, 4))):
            x0 = c[0] + rng.uniform(-0.7, 0.7) * r; y0 = c[1] + rng.uniform(-0.7, 0.7) * r
            L = rng.uniform(0.03, 0.18); w = rng.uniform(0.002, 0.005)
            cm = np.array([x0, y0, c[2] - L / 2])
            jj = kd.query_ball_point(cm, L / 2 + 0.02)
            if jj:
                q = idx[jj]; p_ = pts[jj]
                dh = np.hypot(p_[:, 0] - x0, p_[:, 1] - y0)
                prof = (c[2] - p_[:, 2]) / L
                wloc = w * (1 - 0.6 * prof)
                ok = (prof >= -0.05) & (prof <= 1.0)
                v = np.clip((wloc - dh) / (w * 0.4), 0, 1) * ok
                out[q[:, 0], q[:, 1]] = np.maximum(out[q[:, 0], q[:, 1]], v)
    return out
