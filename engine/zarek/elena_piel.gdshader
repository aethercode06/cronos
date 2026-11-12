// Piel y ropa de Elena: textura del cuerpo + capa de expresión facial (2.º UV) con fundido entre dos caras.
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D cara_a : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D cara_b : source_color, filter_linear_mipmap, repeat_disable;
uniform float mezcla : hint_range(0.0, 1.0) = 0.0;
uniform float rugosidad = 0.88;
uniform float brillo = 0.05;
uniform float ojos_brillo = 0.0;

void fragment() {
	vec3 c = texture(albedo_tex, UV).rgb;
	vec2 f = UV2;
	float dentro = step(0.0, f.x) * step(f.x, 1.0) * step(0.0, f.y) * step(f.y, 1.0);
	vec4 a = texture(cara_a, f);
	vec4 b = texture(cara_b, f);
	vec4 cara = mix(a, b, mezcla);
	float k = cara.a * dentro;
	ALBEDO = mix(c, cara.rgb, k);
	ROUGHNESS = mix(rugosidad, 0.62, k);
	SPECULAR = 0.35;
	// ojos: zona de los ojos de la capa facial (para que brillen en la oscuridad si hace falta)
	float ojo = dentro * smoothstep(0.07, 0.03, min(distance(f, vec2(0.381, 0.546)), distance(f, vec2(0.610, 0.546))));
	EMISSION = ALBEDO * brillo + vec3(1.0, 0.95, 0.85) * ojo * ojos_brillo * k;
}
