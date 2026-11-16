shader_type spatial;
// Agua realista para móvil: dos mapas de olas (ruido normal) que se desplazan en la dirección de la corriente,
// color según la profundidad aparente (oscura en el centro del cauce, turbia en las orillas), reflejo del cielo
// nocturno por Fresnel, brillo especular de la luna/linterna, refracción del fondo y espuma junto a las orillas y
// donde el agua toca piedras (por profundidad de la escena).
render_mode blend_mix, depth_draw_always, cull_back, specular_schlick_ggx;
uniform sampler2D olas1 : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D olas2 : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D espuma_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D pantalla : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D profundidad : hint_depth_texture, filter_nearest;
uniform vec3 color_hondo : source_color = vec3(0.012, 0.03, 0.035);
uniform vec3 color_orilla : source_color = vec3(0.07, 0.075, 0.05);
uniform vec3 color_cielo : source_color = vec3(0.16, 0.19, 0.27);
uniform vec2 corriente = vec2(0.35, 0.0);
uniform float escala = 0.18;
uniform float fuerza_olas = 0.65;
uniform float ancho_orilla = 0.22;   // fracción del ancho (en UV.y) que es orilla
uniform bool es_rio = true;
uniform float espuma_borde = 0.35;   // metros de espuma donde toca algo
varying vec3 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// pequeñas ondulaciones reales del plano
	VERTEX.y += (sin(mundo.x * 1.7 + TIME * 1.3) * 0.012 + sin(mundo.z * 2.3 - TIME * 1.1) * 0.01);
}

void fragment() {
	vec2 p = mundo.xz * escala;
	vec2 c = es_rio ? corriente : vec2(0.02, 0.015);
	vec3 n1 = texture(olas1, p + c * TIME * 0.6).rgb;
	vec3 n2 = texture(olas2, p * 1.9 - vec2(c.y, -c.x) * TIME * 0.25 + c * TIME * 0.9).rgb;
	vec3 n = normalize(mix(n1, n2, 0.5) * 2.0 - 1.0);
	NORMAL_MAP = mix(vec3(0.5, 0.5, 1.0), n * 0.5 + 0.5, fuerza_olas);
	// profundidad aparente: centro del cauce hondo, orillas someras
	float orilla = es_rio ? (1.0 - smoothstep(0.0, ancho_orilla, min(UV.y, 1.0 - UV.y))) : 0.0;
	// profundidad real de lo que hay debajo/detrás (piedras, orilla, fondo de la pila)
	float d = texture(profundidad, SCREEN_UV).r;
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV, d) * 2.0 - 1.0;
	#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, d);
	#endif
	vec4 vp = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float escena = -vp.z / vp.w;
	float grosor = max(escena - (-VERTEX.z), 0.0);
	float toca = 1.0 - smoothstep(0.0, espuma_borde, grosor);
	// refracción: el fondo se ve torcido por las olas
	vec2 ruv = SCREEN_UV + n.xy * 0.025 * (1.0 - toca);
	vec3 fondo = texture(pantalla, ruv).rgb;
	float claridad = clamp(0.35 - orilla * 0.2, 0.05, 0.5) * (1.0 - smoothstep(0.0, 2.5, grosor) * 0.7);
	vec3 agua = mix(color_hondo, color_orilla, orilla * 0.8);
	agua = mix(agua, fondo * 0.6, claridad);
	// reflejo del cielo
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	agua = mix(agua, color_cielo, fres * 0.85);
	// espuma: orillas y contacto con piedras, deshilachada con ruido que corre
	float ruido = texture(espuma_tex, p * 2.2 + c * TIME * 0.8).r;
	float esp = clamp(max(toca * 1.2, orilla * 0.35 * float(es_rio)) * smoothstep(0.35, 0.8, ruido + toca * 0.4), 0.0, 1.0);
	// vetas de corriente: líneas de espuma fina estiradas en la dirección del agua
	if (es_rio) {
		float veta = texture(espuma_tex, vec2(p.x * 0.25 - TIME * c.x * 1.4, p.y * 2.6 + sin(p.x * 0.8) * 0.2)).r;
		esp = max(esp, smoothstep(0.72, 0.9, veta) * 0.45);
	}
	ALBEDO = mix(agua, vec3(0.55, 0.58, 0.6), esp * 0.7);
	ROUGHNESS = mix(0.04, 0.6, esp);
	METALLIC = 0.0;
	SPECULAR = 0.6;
	ALPHA = 1.0;
}
