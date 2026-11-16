shader_type spatial;
// Suelo del exterior con relieve real: oclusión por paralaje (las hojas, piedras y terrones sobresalen y se tapan
// unos a otros según el ángulo), mezcla de capas por altura (la hojarasca queda encima del barro, el musgo entre
// las piedras), oclusión ambiental y sombreado de huecos. Tres capas en coordenadas del mundo, sin repetición
// visible (dos escalas y giros, manchas de ruido y variación de tono a gran escala).
uniform sampler2D c1 : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D n1 : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D r1 : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform sampler2D h1 : filter_linear_mipmap, repeat_enable;
uniform sampler2D a1 : filter_linear_mipmap, repeat_enable;
uniform sampler2D c2 : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D n2 : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D h2 : filter_linear_mipmap, repeat_enable;
uniform sampler2D c3 : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D n3 : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D h3 : filter_linear_mipmap, repeat_enable;
uniform sampler2D ruido : filter_linear_mipmap, repeat_enable;
uniform float escala = 0.25;
uniform vec3 tinte1 : source_color = vec3(1.0);
uniform vec3 tinte2 : source_color = vec3(1.0);
uniform vec3 tinte3 : source_color = vec3(1.0);
uniform float cantidad2 = 0.35;
uniform float cantidad3 = 0.25;
uniform float relieve = 0.06;      // altura del relieve en metros
uniform bool con_alturas = false;
uniform float max_pasos = 12.0;  // pasos del relieve (4 en el teléfono)
uniform float dist_relieve = 14.0;
varying vec3 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec2 girar(vec2 p, float a) {
	float c = cos(a), s = sin(a);
	return mat2(vec2(c, s), vec2(-s, c)) * p;
}

void fragment() {
	vec2 p = mundo.xz * escala;
	// paralaje: busca dónde corta el rayo de vista con el relieve de la capa base (solo cerca y en suelo horizontal)
	vec3 v_mundo = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	float dist = length(VERTEX);
	if (con_alturas && dist < dist_relieve && v_mundo.y > 0.15) {
		int pasos = int(mix(max_pasos, 2.0, clamp(dist / dist_relieve, 0.0, 1.0)));
		vec2 delta = -v_mundo.xz / v_mundo.y * relieve * escala / float(pasos);
		float capa = 1.0;
		float paso_h = 1.0 / float(pasos);
		vec2 q = p;
		float hq = texture(h1, q).r;
		for (int i = 0; i < 12; i++) {
			if (i >= pasos || capa <= hq) break;
			capa -= paso_h;
			q += delta;
			hq = texture(h1, q).r;
		}
		// afinado entre los dos últimos pasos
		vec2 qa = q - delta;
		float ha = texture(h1, qa).r - (capa + paso_h);
		float hb = hq - capa;
		float t = clamp(hb / max(hb - ha, 0.0001), 0.0, 1.0);
		p = mix(q, qa, t) * mix(1.0, 0.0, smoothstep(10.0, 14.0, dist)) + p * smoothstep(10.0, 14.0, dist);
	}
	float m1 = texture(ruido, mundo.xz * 0.011).r;
	float m2 = texture(ruido, mundo.xz * 0.023 + vec2(0.37, 0.71)).r;
	float m3 = texture(ruido, mundo.xz * 0.004 + vec2(0.13, 0.29)).r;
	vec2 pa = p;
	vec2 pb = girar(p * 0.61, 1.1) + vec2(0.31, 0.17);
	float mezcla = smoothstep(0.3, 0.7, texture(ruido, mundo.xz * 0.05).r);
	vec3 col1 = mix(texture(c1, pa).rgb, texture(c1, pb).rgb, mezcla) * tinte1;
	vec3 nor1 = mix(texture(n1, pa).rgb, texture(n1, pb).rgb, mezcla);
	float alt1 = con_alturas ? texture(h1, pa).r : 0.5;
	vec2 p2 = girar(p * 0.8, 0.6);
	vec2 p3 = girar(p * 1.2, 2.3);
	vec3 col2 = texture(c2, p2).rgb * tinte2;
	vec3 nor2 = texture(n2, p2).rgb;
	float alt2 = con_alturas ? texture(h2, p2).r : 0.5;
	vec3 col3 = texture(c3, p3).rgb * tinte3;
	vec3 nor3 = texture(n3, p3).rgb;
	float alt3 = con_alturas ? texture(h3, p3).r : 0.5;
	// mezcla por altura: en el borde de cada mancha gana lo que está más alto
	float w2 = smoothstep(1.0 - cantidad2 - 0.06, 1.0 - cantidad2 + 0.06, m1 + (alt2 - alt1) * 0.35);
	float w3 = smoothstep(1.0 - cantidad3 - 0.06, 1.0 - cantidad3 + 0.06, m2 + (alt3 - max(alt1, alt2 * w2)) * 0.35) * (1.0 - w2 * 0.7);
	vec3 col = mix(mix(col1, col2, w2), col3, w3);
	vec3 nor = mix(mix(nor1, nor2, w2), nor3, w3);
	float alt = mix(mix(alt1, alt2, w2), alt3, w3);
	col *= mix(0.72, 1.12, m3);
	// huecos más oscuros (entre hojas y piedras se acumula la sombra)
	float ao = con_alturas ? texture(a1, pa).r : 1.0;
	col *= mix(0.55, 1.05, smoothstep(0.0, 0.7, alt)) * mix(0.8, 1.0, ao);
	float rug = mix(texture(r1, pa).r, 0.75, w2 * 0.5) * mix(0.85, 1.0, m3);
	ALBEDO = col;
	NORMAL_MAP = nor;
	NORMAL_MAP_DEPTH = 1.6;
	ROUGHNESS = rug;
	AO = ao;
	AO_LIGHT_AFFECT = 0.3;
}
