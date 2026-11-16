shader_type spatial;
// Suelo del exterior sin repeticiones visibles: tres capas reales (hojarasca, barro, musgo) mezcladas con manchas
// de ruido en coordenadas del mundo, cada capa muestreada a dos escalas y giros distintos, y variación de tono
// a gran escala. Todo en el plano XZ del mundo.
uniform sampler2D c1 : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D n1 : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D r1 : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform sampler2D c2 : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D n2 : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D c3 : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D n3 : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ruido : filter_linear_mipmap, repeat_enable;
uniform float escala = 0.25;
uniform vec3 tinte1 : source_color = vec3(1.0);
uniform vec3 tinte2 : source_color = vec3(1.0);
uniform vec3 tinte3 : source_color = vec3(1.0);
uniform float cantidad2 = 0.35;
uniform float cantidad3 = 0.25;
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
	float m1 = texture(ruido, mundo.xz * 0.011).r;
	float m2 = texture(ruido, mundo.xz * 0.023 + vec2(0.37, 0.71)).r;
	float m3 = texture(ruido, mundo.xz * 0.004 + vec2(0.13, 0.29)).r;
	// la misma capa a dos escalas y giros: rompe la cuadrícula de repetición
	vec2 pa = p;
	vec2 pb = girar(p * 0.61, 1.1) + vec2(0.31, 0.17);
	float mezcla = smoothstep(0.3, 0.7, texture(ruido, mundo.xz * 0.05).r);
	vec3 col1 = mix(texture(c1, pa).rgb, texture(c1, pb).rgb, mezcla) * tinte1;
	vec3 nor1 = mix(texture(n1, pa).rgb, texture(n1, pb).rgb, mezcla);
	vec3 col2 = texture(c2, girar(p * 0.8, 0.6)).rgb * tinte2;
	vec3 nor2 = texture(n2, girar(p * 0.8, 0.6)).rgb;
	vec3 col3 = texture(c3, girar(p * 1.2, 2.3)).rgb * tinte3;
	vec3 nor3 = texture(n3, girar(p * 1.2, 2.3)).rgb;
	float w2 = smoothstep(1.0 - cantidad2 - 0.08, 1.0 - cantidad2 + 0.08, m1);
	float w3 = smoothstep(1.0 - cantidad3 - 0.08, 1.0 - cantidad3 + 0.08, m2) * (1.0 - w2 * 0.7);
	vec3 col = mix(mix(col1, col2, w2), col3, w3);
	vec3 nor = mix(mix(nor1, nor2, w2), nor3, w3);
	// variación de tono a gran escala (zonas más húmedas y oscuras, otras más secas)
	col *= mix(0.72, 1.12, m3);
	float rug = mix(texture(r1, pa).r, 0.75, w2 * 0.5) * mix(0.85, 1.0, m3);
	ALBEDO = col;
	NORMAL_MAP = nor;
	NORMAL_MAP_DEPTH = 1.1;
	ROUGHNESS = rug;
}
