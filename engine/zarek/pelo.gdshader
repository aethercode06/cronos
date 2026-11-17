shader_type spatial;
// Pelaje por capas («shell fur»): la malla del animal se dibuja varias veces, cada capa un poco hacia fuera
// por la normal, y en cada capa solo quedan los puntos donde hay un pelo lo bastante largo. Da pelo de verdad
// (suave al contorno, con volumen) en vez de una piel de plástico.
render_mode cull_back, depth_draw_opaque;

uniform sampler2D color_piel : source_color, filter_linear_mipmap;
uniform sampler2D mapa_largo : hint_default_white, filter_linear;  // 1 = pelo largo, 0 = sin pelo
uniform vec3 tinte : source_color = vec3(1.0);
uniform float capa = 0.0;          // 0 = piel, 1 = punta del pelo
uniform float largo = 0.006;       // largo del pelo (unidades del modelo ya escaladas en el mundo, aprox.)
uniform float densidad = 900.0;    // pelos por unidad de UV
uniform float gravedad = 0.35;     // el pelo cae un poco
uniform float oscuro_raiz = 0.45;

// islas UV sin pelo (coordenadas UV de Godot): ojos, nariz, lengua; las orejas por dentro con poco pelo
uniform vec4 sin_pelo_1 = vec4(0.828, 0.908, 0.907, 0.994);
uniform vec4 sin_pelo_2 = vec4(0.650, 0.908, 0.817, 0.999);
uniform vec4 sin_pelo_3 = vec4(0.955, 0.902, 0.999, 0.999);
uniform vec4 poco_pelo = vec4(0.070, 0.926, 0.364, 0.999);
bool en(vec2 uv, vec4 r) { return uv.x > r.x && uv.x < r.z && uv.y > r.y && uv.y < r.w; }

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void vertex() {
	vec3 n = normalize(NORMAL);
	float l = largo * texture(mapa_largo, UV).r;
	VERTEX += n * l * capa;
	// la punta se dobla hacia abajo (en espacio del modelo, -Y aproximado)
	VERTEX.y -= l * gravedad * capa * capa;
}

void fragment() {
	bool ojo = en(UV, sin_pelo_1);
	bool liso = ojo || en(UV, sin_pelo_2) || en(UV, sin_pelo_3);
	if (capa > 0.0 && (liso || (en(UV, poco_pelo) && capa > 0.35))) {
		discard;
	}
	// pelos en posiciones aleatorias dentro de cada celda (sin rejilla visible), peinados: la punta se desplaza
	vec2 q = UV * densidad + vec2(0.35, 0.6) * capa * 1.2;
	vec2 celda = floor(q);
	vec2 centro = vec2(hash(celda + 3.1), hash(celda + 9.7)) * 0.6 + 0.2;
	float alto = hash(celda) * 0.6 + 0.4 * hash(celda + 1.7);
	vec2 dentro = fract(q) - centro;
	float grosor = (1.0 - capa) * (0.32 + 0.18 * hash(celda + 5.3)) + 0.04;
	if (capa > 0.0 && (alto < capa || length(dentro) > grosor)) {
		discard;
	}
	// cada pelo toma el color de un punto cercano (no exactamente el suyo): los pelos cruzan los bordes de las
	// rayas como en un gato de verdad, y la punta es algo más clara (pelo «agutí»)
	vec2 desv = (vec2(hash(celda + 11.0), hash(celda + 13.0)) - 0.5) * 0.006 * capa;
	vec3 c = texture(color_piel, UV + desv).rgb * tinte;
	c *= 1.0 + 0.12 * capa * capa;
	// variación de color pelo a pelo y oscuridad en la raíz (oclusión)
	c *= 0.88 + 0.24 * hash(celda + 7.0);
	c *= mix(oscuro_raiz, 1.0, capa);
	if (liso) {
		c = texture(color_piel, UV).rgb * tinte;
	}
	ALBEDO = c;
	ROUGHNESS = ojo ? 0.03 : (liso ? 0.45 : 0.85);
	SPECULAR = ojo ? 0.9 : 0.25;

	// brillo del pelo al contraluz
	RIM = 0.25 * capa;
	RIM_TINT = 0.5;
}
