shader_type spatial;
// Vegetación con viento: toda la planta se cimbrea más cuanto más alta (curva cuadrática desde la base), con
// fases distintas por planta (posición en el mundo) y rachas; las hojas además tiemblan rápido.
// viento (global): xy = dirección en el suelo, z = fuerza (0..1.5), w = racha (0..1).
render_mode cull_disabled;
global uniform vec4 viento;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rough_tex : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform vec4 color : source_color = vec4(1.0);
uniform bool usa_albedo = false;
uniform bool usa_normal = false;
uniform bool usa_rough = false;
uniform float rugosidad = 0.85;
uniform float corte = 0.0;          // recorte alfa (0 = opaco)
uniform float altura = 1.0;         // alto de la planta en su malla (para la curva)
uniform float flex = 0.06;          // cuánto se dobla (fracción de la altura)
uniform float temblor = 0.0;        // temblor de hojas (m)
uniform vec3 trasluz : source_color = vec3(0.0);
uniform vec2 uv_escala = vec2(1.0);

void vertex() {
	vec3 raiz = MODEL_MATRIX[3].xyz;
	float fase = dot(raiz.xz, vec2(0.37, 0.61));
	float h = clamp(VERTEX.y / max(altura, 0.01), 0.0, 1.5);
	float f = viento.z * (0.55 + 0.45 * sin(TIME * 0.9 + fase)) + viento.w * (0.6 + 0.4 * sin(TIME * 2.7 + fase * 1.3));
	float cimbreo = (sin(TIME * 1.3 + fase) * 0.35 + 0.65) * f + sin(TIME * 3.1 + fase * 2.0) * 0.12 * f;
	vec3 dir_mundo = normalize(vec3(viento.x, 0.0, viento.y) + vec3(0.0001));
	vec3 dir_local = normalize(inverse(mat3(MODEL_MATRIX)) * dir_mundo);
	float d = h * h * flex * altura * cimbreo;
	VERTEX += dir_local * d;
	VERTEX.y -= d * d / max(altura, 0.01) * 0.5;
	if (temblor > 0.0) {
		float t = sin(TIME * 9.0 + dot(VERTEX, vec3(5.1, 4.3, 3.7)) + fase) * temblor * (0.4 + f) * h;
		VERTEX += NORMAL * t;
	}
	UV *= uv_escala;
}

void fragment() {
	vec4 c = color;
	if (usa_albedo) {
		c *= texture(albedo_tex, UV);
	}
	ALBEDO = c.rgb;
	if (corte > 0.0) {
		ALPHA = c.a;
		ALPHA_SCISSOR_THRESHOLD = corte;
	}
	if (usa_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
	}
	ROUGHNESS = usa_rough ? texture(rough_tex, UV).r : rugosidad;
	BACKLIGHT = trasluz;
}
