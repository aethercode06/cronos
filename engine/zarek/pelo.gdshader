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
	vec2 celda = floor(UV * densidad);
	float alto = hash(celda);                    // largo de este pelo (0..1)
	vec2 dentro = fract(UV * densidad) - 0.5;
	float grosor = (1.0 - capa) * 0.55 + 0.08;   // los pelos se afinan hacia la punta
	if (capa > 0.0 && (alto < capa || length(dentro) > grosor)) {
		discard;
	}
	vec3 c = texture(color_piel, UV).rgb * tinte;
	// variación de color pelo a pelo y oscuridad en la raíz (oclusión)
	c *= 0.85 + 0.3 * hash(celda + 7.0);
	c *= mix(oscuro_raiz, 1.0, capa);
	if (liso) {
		c = texture(color_piel, UV).rgb * tinte;
	}
	ALBEDO = c;
	ROUGHNESS = ojo ? 0.03 : (liso ? 0.45 : 0.85);
	SPECULAR = ojo ? 0.9 : 0.25;
	if (ojo) {
		// el fondo del ojo devuelve la luz (brillo de ojos de gato)
		EMISSION = c * 0.6;
	}
	// brillo del pelo al contraluz
	RIM = 0.25 * capa;
	RIM_TINT = 0.5;
}
