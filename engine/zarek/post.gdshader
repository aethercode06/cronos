shader_type canvas_item;
// Filtro de terror de Zarek: imagen de película vieja y enferma.
// - Gradación: sombras verde azuladas, medios amarillentos enfermizos, luces apagadas; poca saturación y negros
//   aplastados con un velo verdoso (como película revelada mal).
// - Lente: leve distorsión de barril, aberración cromática en los bordes y viñeta irregular que «respira».
// - Película: grano animado, polvo y rayas verticales que aparecen a ratos, y un ligero parpadeo de exposición.
// - Miedo (0..1, sube con la cordura baja y el peligro): más distorsión, aberración, ondulación de la imagen,
//   desaturación y un tinte rojizo; a veces la imagen tiembla un fotograma.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float saturacion = 0.62;
uniform float vineta = 0.72;
uniform float grano = 0.065;
uniform float aberracion = 0.0028;
uniform float distorsion = 0.035;
uniform float contraste = 1.16;
uniform vec3 tinte_sombras : source_color = vec3(0.78, 0.98, 1.0);
uniform vec3 tinte_medios : source_color = vec3(1.0, 0.98, 0.84);
uniform vec3 tinte_luces : source_color = vec3(1.02, 0.97, 0.88);
uniform vec3 velo : source_color = vec3(0.012, 0.022, 0.02);
uniform float brillo = 1.0;
uniform float miedo : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float hash1(float x) { return fract(sin(x * 91.3458) * 47453.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	float t = TIME;
	vec2 uv = SCREEN_UV;
	// temblor de un fotograma cuando el miedo es alto
	float salto = step(0.985 - miedo * 0.05, hash1(floor(t * 24.0))) * miedo;
	uv.x += (hash1(floor(t * 24.0) + 3.0) - 0.5) * 0.02 * salto;
	// ondulación tipo calor/mareo con el miedo
	uv += vec2(sin(uv.y * 18.0 + t * 2.3), cos(uv.x * 14.0 + t * 1.7)) * 0.0025 * miedo;
	// distorsión de barril
	vec2 c = uv - 0.5;
	float r2 = dot(c, c);
	uv = 0.5 + c * (1.0 + (distorsion + miedo * 0.05) * r2);
	c = uv - 0.5;
	r2 = dot(c, c);
	// aberración cromática en los bordes
	vec2 off = c * (aberracion + miedo * 0.006) * r2 * 4.0;
	vec3 col;
	col.r = texture(screen_tex, uv + off).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - off).b;
	// píxeles con valores imposibles (desbordes de la GPU del móvil): se cambian por negro suave en vez de manchas
	if (any(isnan(col)) || any(isinf(col))) col = vec3(0.02);
	col = clamp(col, vec3(0.0), vec3(8.0));
	// parpadeo de exposición muy leve
	col *= 0.97 + 0.03 * ruido(vec2(t * 9.0, 0.0));
	// gradación por zonas de luz
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, saturacion - miedo * 0.3);
	float wS = 1.0 - smoothstep(0.0, 0.25, l);
	float wL = smoothstep(0.35, 0.9, l);
	float wM = 1.0 - wS - wL;
	col *= tinte_sombras * wS + tinte_medios * max(wM, 0.0) + tinte_luces * wL;
	col = (col - 0.45) * contraste + 0.45;
	col = max(col, vec3(0.0)) + velo;
	// tinte rojizo de pánico
	col = mix(col, col * vec3(1.25, 0.72, 0.68), miedo * 0.45);
	// viñeta irregular que respira
	float resp = 0.5 + 0.5 * sin(t * (0.6 + miedo * 2.0));
	float irregular = ruido(c * 3.0 + vec2(t * 0.05)) * 0.12;
	col *= 1.0 - (vineta + miedo * 0.25 + resp * 0.06) * smoothstep(0.06, 0.5 + irregular, r2);
	// polvo y rayas de película vieja
	float raya_x = hash1(floor(t * 12.0));
	float raya = step(0.6, hash1(floor(t * 12.0) + 7.0)) * smoothstep(0.0012, 0.0, abs(uv.x - raya_x)) * 0.25;
	vec2 pg = floor(uv * vec2(320.0, 180.0));
	float polvo = step(0.9985, hash(pg + floor(t * 12.0) * 13.1)) * 0.35;
	col = mix(col, vec3(0.75, 0.72, 0.62), raya);
	col -= polvo;
	// grano
	float n = hash(SCREEN_UV * vec2(1920.0, 1080.0) + fract(t * 7.13) * 91.7) - 0.5;
	col += n * (grano + miedo * 0.05) * (1.0 - l * 0.5);
	COLOR = vec4(max(col * brillo, vec3(0.0)), 1.0);
}
