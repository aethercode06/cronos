shader_type spatial;
// Agua realista. Técnica de Waterways (Kasper Arnklit Frandsen, MIT, github.com/Arnklit/Waterways):
// - dos fases de UV desplazadas por la corriente que se mezclan en el tiempo (el agua fluye sin saltos ni estirones),
//   con un mapa de olas real (rg = normal, b = ruido de espuma) a dos escalas;
// - el fondo se ve a través del agua (refracción) y se va oscureciendo y tiñendo con la profundidad real
//   (lectura del búfer de profundidad); la luz que atraviesa el agua va por EMISSION y el color propio por ALBEDO;
// - espuma donde el agua es poco profunda (orillas, piedras, chorros) y donde la corriente la arrastra.
// Añadido para Zarek: reflejo del cielo nocturno por Fresnel, compatibilidad con el renderizador de móviles antiguos.
render_mode depth_draw_always, specular_schlick_ggx, cull_back;
uniform sampler2D olas : hint_default_black, repeat_enable, filter_linear_mipmap;
uniform sampler2D espuma_ruido : hint_default_white, repeat_enable, filter_linear_mipmap;
uniform sampler2D pantalla : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D profundidad : hint_depth_texture, repeat_disable, filter_nearest;
uniform vec2 corriente = vec2(1.0, 0.0);   // dirección de la corriente en el suelo (mundo XZ)
uniform float fuerza = 1.2;                // cuánto arrastra la corriente las olas
uniform float velocidad = 0.6;
uniform float escala = 0.22;               // repeticiones del mapa de olas por metro
uniform float relieve = 1.0;
uniform float rugosidad = 0.05;
uniform vec3 color_cerca : source_color = vec3(0.05, 0.085, 0.07);
uniform vec3 color_lejos : source_color = vec3(0.008, 0.02, 0.025);
uniform float hondura_color = 1.6;         // metros hasta el color de fondo
uniform float claridad = 1.4;              // metros hasta que deja de verse el fondo
uniform float refraccion = 0.05;
uniform vec3 color_espuma : source_color = vec3(0.72, 0.74, 0.72);
uniform float espuma = 1.6;
uniform float espuma_orilla = 0.35;        // metros de agua somera con espuma
uniform vec3 color_cielo : source_color = vec3(0.16, 0.19, 0.27);
uniform vec3 luna_dir = vec3(0.645, -0.616, -0.452);     // dirección hacia la que va la luz de la luna
uniform vec3 color_luna : source_color = vec3(0.55, 0.65, 0.95);
uniform float borde = 0.06;
varying vec3 mundo;

vec3 flujo_uvw(vec2 uv, vec2 f, vec2 salto, float t, bool b) {
	float desfase = b ? 0.5 : 0.0;
	float avance = fract(t + desfase);
	vec3 r;
	r.xy = uv - f * (avance - 0.5);
	r.xy += desfase;
	r.xy += (t - avance) * salto;
	r.z = 1.0 - abs(1.0 - 2.0 * avance);
	return r;
}

float vista_z(vec2 suv, mat4 inv_proy) {
	float d = textureLod(profundidad, suv, 0.0).r;
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec4 v = inv_proy * vec4(suv * 2.0 - 1.0, d * 2.0 - 1.0, 1.0);
	#else
	vec4 v = inv_proy * vec4(suv * 2.0 - 1.0, d, 1.0);
	#endif
	return v.z / v.w;
}

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = mundo.xz * escala;
	vec2 f = normalize(corriente + vec2(0.0001)) * fuerza;
	float t = TIME * velocidad;
	vec3 a1 = flujo_uvw(uv, f, vec2(0.24, 0.2083333), t, false);
	vec3 b1 = flujo_uvw(uv, f, vec2(0.24, 0.2083333), t, true);
	vec3 a2 = flujo_uvw(uv * 2.0, f, vec2(0.20, 0.25), t, false);
	vec3 b2 = flujo_uvw(uv * 2.0, f, vec2(0.20, 0.25), t, true);
	vec3 w1 = texture(olas, a1.xy).rgb * a1.z + texture(olas, b1.xy).rgb * b1.z;
	vec3 w2 = texture(olas, a2.xy).rgb * a2.z + texture(olas, b2.xy).rgb * b2.z;
	vec2 nor = w1.rg * 0.65 + w2.rg * 0.35;
	float fbm = w1.b * w2.b * 2.0;
	// profundidad real del agua en este punto
	float sz = vista_z(SCREEN_UV, INV_PROJECTION_MATRIX);
	float hondo = max(VERTEX.z - sz, 0.0);
	// espuma: agua somera (orillas, piedras) y algo arrastrada por la corriente
	float azar = texture(espuma_ruido, uv * 0.5 + f * t * 0.05).r;
	float mascara = clamp((1.0 - smoothstep(0.0, espuma_orilla, hondo)) * 1.4 + azar * 0.15 * fuerza, 0.0, 1.0);
	float esp = clamp(fbm * espuma - 0.5 / max(espuma, 0.001), 0.0, 1.0);
	float esp_total = clamp(mix(clamp(esp - (1.0 - mascara), 0.0, 1.0), esp * mascara, 0.3), 0.0, 1.0);
	SPECULAR = 0.35;
	ROUGHNESS = max(mix(rugosidad, 0.7, esp_total), 0.12);
	NORMAL_MAP = vec3(nor, 0.0);
	NORMAL_MAP_DEPTH = relieve;
	// refracción con el fondo
	vec3 n = NORMAL_MAP * 2.0 - 1.0;
	vec3 rv = TANGENT * n.x + BINORMAL * n.y;
	vec3 rn = (length(rv) > 0.0001 ? normalize(rv) : vec3(0.0)) * relieve * 0.1;
	vec2 ro = SCREEN_UV - rn.xy * refraccion;
	float sz2 = vista_z(ro, INV_PROJECTION_MATRIX);
	float hondo2 = max(VERTEX.z - sz2, 0.0);
	if (sz2 > VERTEX.z) {
		ro = SCREEN_UV;
		hondo2 = hondo;
	}
	float cla = clamp(pow(clamp(hondo2 / max(claridad, 0.001), 0.0, 1.0), 0.5), 0.0, 1.0);
	float pasa = 1.0 - clamp(cla + esp_total, 0.0, 1.0);
	vec3 col = mix(color_cerca, color_lejos, pow(clamp(hondo2 / max(hondura_color, 0.001), 0.0, 1.0), 0.5));
	// reflejo del cielo según el ángulo (de lado el agua refleja más)
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 5.0);
	col = mix(col, color_cielo, fres * 0.9);
	// reflejo de lo que hay alrededor (árboles, ventanas encendidas, linterna): se refleja la imagen de la
	// pantalla respecto a la línea del horizonte del agua, torcida por las olas (barato y convincente de noche)
	vec3 cam = CAMERA_POSITION_WORLD;
	vec3 fwd = -INV_VIEW_MATRIX[2].xyz;
	fwd.y = 0.0;
	fwd = normalize(fwd + vec3(0.0001));
	vec3 lejos = cam + fwd * 400.0;
	lejos.y = mundo.y;
	vec4 clip = PROJECTION_MATRIX * VIEW_MATRIX * vec4(lejos, 1.0);
	float horizonte = clip.y / clip.w * 0.5 + 0.5;
	vec2 ruv = vec2(SCREEN_UV.x, 2.0 * horizonte - SCREEN_UV.y) + n.xy * 0.035;
	float dentro_p = step(0.0, ruv.y) * step(ruv.y, 1.0) * smoothstep(0.0, 0.08, ruv.y) * smoothstep(1.0, 0.92, ruv.y);
	vec3 reflejo = textureLod(pantalla, clamp(ruv, vec2(0.001), vec2(0.999)), 1.5).rgb * dentro_p;
	float k_refl = mix(0.25, 0.85, fres) * (1.0 - esp_total);
	// destello de la luna sobre las ondas (reflejo especular nítido, como en el agua de verdad)
	vec3 l_vista = normalize((VIEW_MATRIX * vec4(-luna_dir, 0.0)).xyz);
	vec3 refl = reflect(-VIEW, NORMAL);
	float brillo = pow(max(dot(refl, l_vista), 0.0), 220.0) * 6.0 + pow(max(dot(refl, l_vista), 0.0), 18.0) * 0.12;
	ALBEDO = mix(col, color_espuma, esp_total) * (1.0 - pasa);
	EMISSION += color_luna * brillo * (1.0 - esp_total) + color_cielo * fres * 0.6 + reflejo * k_refl;
	EMISSION += textureLod(pantalla, ro, rugosidad * hondo2 * 2.0).rgb * pasa * (1.0 - fres * 0.6);
	ALPHA = smoothstep(0.0, max(borde, 0.001), hondo);
}
