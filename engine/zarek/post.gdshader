shader_type canvas_item;
// Posprocesado de cine para Zarek: gradación fría en sombras, cálida en luces, menos saturación,
// viñeta, grano de película y una pizca de aberración cromática en los bordes.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float saturacion = 0.78;
uniform float vineta = 0.55;
uniform float grano = 0.045;
uniform float aberracion = 0.0016;
uniform vec3 tinte_sombras = vec3(0.86, 0.95, 1.12);
uniform vec3 tinte_luces = vec3(1.06, 1.0, 0.9);
uniform float contraste = 1.08;

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	float r2 = dot(c, c);
	vec2 off = c * aberracion * r2 * 4.0;
	vec3 col;
	col.r = texture(screen_tex, uv + off).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - off).b;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, saturacion);
	col = mix(col * tinte_sombras, col * tinte_luces, smoothstep(0.05, 0.6, l));
	col = (col - 0.5) * contraste + 0.5;
	col *= 1.0 - vineta * smoothstep(0.08, 0.55, r2);
	float n = hash(uv * vec2(1920.0, 1080.0) + fract(TIME * 7.13) * 91.7) - 0.5;
	col += n * grano * (1.0 - l * 0.6);
	COLOR = vec4(max(col, vec3(0.0)), 1.0);
}
