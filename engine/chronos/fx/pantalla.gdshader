shader_type canvas_item;
// Efectos de pantalla de Chronos: distorsión de la dimensión violeta, calor del volcán,
// ondas bajo el agua y viñeta. Se aplica sobre todo lo dibujado debajo.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float violeta = 0.0;
uniform float calor = 0.0;
uniform float agua = 0.0;
uniform float vineta = 0.35;
uniform float tiempo_lento = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = TIME;
	uv.x += sin(uv.y * 40.0 + t * 3.0) * 0.0025 * calor * smoothstep(0.3, 1.0, uv.y);
	uv += vec2(sin(uv.y * 18.0 + t * 2.0), cos(uv.x * 14.0 + t * 1.6)) * 0.004 * agua;
	uv.x += sin(uv.y * 9.0 + t * 1.3) * 0.003 * violeta;
	vec3 c = textureLod(screen_tex, uv, 0.0).rgb;
	if (violeta > 0.0) {
		float r = textureLod(screen_tex, uv + vec2(0.003, 0.0) * violeta, 0.0).r;
		float b = textureLod(screen_tex, uv - vec2(0.003, 0.0) * violeta, 0.0).b;
		c = mix(c, vec3(r, c.g, b) * vec3(1.05, 0.9, 1.15), 0.6 * violeta);
	}
	if (tiempo_lento > 0.0) {
		float g = dot(c, vec3(0.3, 0.59, 0.11));
		c = mix(c, vec3(g * 0.8, g * 0.95, g * 1.15), 0.45 * tiempo_lento);
	}
	vec2 d = SCREEN_UV - 0.5;
	c *= 1.0 - vineta * smoothstep(0.35, 0.85, length(d * vec2(1.2, 1.0)));
	COLOR = vec4(c, 1.0);
}
