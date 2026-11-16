shader_type spatial;
// Fachada de sillería envejecida: piedra en proyección triplanar del mundo, con suciedad de un siglo:
// churretes verticales de lluvia, base más oscura y verdosa (humedad y musgo) y manchas a gran escala.
uniform sampler2D c_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D n_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D r_tex : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform sampler2D ao_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D ruido : filter_linear_mipmap, repeat_enable;
uniform vec3 tinte : source_color = vec3(0.78, 0.75, 0.7);
uniform float escala = 0.33;
uniform float suciedad = 1.0;
varying vec3 mpos;
varying vec3 mnor;

void vertex() {
	mpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	mnor = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

#define TRI(t, p, w) (texture(t, p.zy).rgb * w.x + texture(t, p.xz).rgb * w.y + texture(t, p.xy).rgb * w.z)

void fragment() {
	vec3 w = pow(abs(mnor), vec3(4.0));
	w /= (w.x + w.y + w.z);
	vec3 p = mpos * escala;
	vec3 col = TRI(c_tex, p, w) * tinte;
	vec3 nm = TRI(n_tex, p, w);
	float ao = TRI(ao_tex, p, w).r;
	float ru = TRI(r_tex, p, w).r;
	// churretes: ruido estirado en vertical, más fuertes bajo los salientes (aprox. cada piso)
	float h = mpos.y;
	vec2 q = vec2(dot(mpos.xz, vec2(0.7, 0.7)) * 0.9, h * 0.06);
	float chorreo = texture(ruido, q).r;
	float bajo_cornisa = smoothstep(0.2, 0.0, fract(h / 3.6 + 0.05)) * 0.6 + 0.4;
	float sucio = smoothstep(0.45, 0.8, chorreo) * bajo_cornisa;
	// base húmeda: más oscura y algo verde hasta ~1,2 m
	float base = 1.0 - smoothstep(0.0, 1.3, h);
	float manchas = texture(ruido, mpos.xz * 0.02 + vec2(h * 0.01)).r;
	col *= 1.0 - sucio * 0.35 * suciedad;
	col = mix(col, col * vec3(0.55, 0.6, 0.5), base * 0.7 * suciedad);
	col *= mix(0.85, 1.08, manchas);
	ALBEDO = col * mix(0.75, 1.0, ao);
	NORMAL_MAP = nm;
	NORMAL_MAP_DEPTH = 1.2;
	ROUGHNESS = clamp(ru + base * 0.1, 0.0, 1.0);
	AO = ao;
	AO_LIGHT_AFFECT = 0.4;
}
