shader_type spatial;
// Agua que cae del borde de una taza de la fuente: muchos hilos finos separados (no una cortina), cada uno con su
// grosor y su ritmo, que se rompen en gotas al bajar; casi transparentes, con brillo donde les da la luz.
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform sampler2D ruido : filter_linear_mipmap, repeat_enable;
uniform vec3 color : source_color = vec3(0.36, 0.42, 0.46);
uniform float velocidad = 2.2;
uniform float hilos = 46.0;   // hilos de agua alrededor del borde

float hash(float x) { return fract(sin(x * 127.1) * 43758.5453); }

void fragment() {
	float col = floor(UV.x * hilos);
	float h = hash(col);
	// cada hilo tiene su grosor; uno de cada cuatro casi no lleva agua
	float grosor = mix(0.06, 0.28, h) * step(0.22, hash(col + 7.3));
	float x = fract(UV.x * hilos) - 0.5;
	// el hilo se ondula un poco al caer
	x += sin(UV.y * 9.0 + h * 6.28 + TIME * 3.0) * 0.06;
	float hilo = 1.0 - smoothstep(grosor * 0.4, grosor, abs(x));
	// textura de flujo que baja: rompe el hilo en tramos y gotas, más abajo
	vec2 uvf = vec2(UV.x * 3.0 + h, UV.y * 1.6 - TIME * velocidad * (0.8 + h * 0.5));
	float flujo = texture(ruido, uvf).r;
	float roto = smoothstep(0.25 + UV.y * 0.35, 0.6 + UV.y * 0.2, flujo);
	float abajo = smoothstep(0.75, 1.0, UV.y);
	float fres = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 3.0);
	ALBEDO = mix(color, vec3(0.75, 0.8, 0.82), abajo * 0.5);
	ROUGHNESS = 0.22;
	SPECULAR = 0.65;
	float a = hilo * roto * (0.35 + fres * 0.3) + abajo * 0.12 * flujo;
	ALPHA = clamp(a * smoothstep(0.0, 0.05, UV.y), 0.0, 0.6);
}
