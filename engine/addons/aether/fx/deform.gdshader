shader_type canvas_item;
// Aether Engine — deformación de malla para dar vida a un dibujo de una sola pose.
// La imagen se reparte en una rejilla de vértices; cada parámetro mueve una zona:
// aplastar/estirar desde los pies, inclinar, inflar la panza, adelantar la cabeza,
// abrir la boca, temblar y respirar.

uniform vec2 size = vec2(400.0, 360.0);    // tamaño del dibujo en píxeles locales
uniform float squash = 1.0;                // <1 aplastado, >1 estirado
uniform float lean = 0.0;                  // inclinación hacia delante (+) o atrás (-)
uniform float belly = 0.0;                 // inflar la panza
uniform vec2 belly_center = vec2(0.5, 0.68);
uniform float head = 0.0;                  // adelantar la cabeza (+) o echarla atrás (-)
uniform float jaw = 0.0;                   // abrir la boca (separa la mitad superior)
uniform float mouth_y = 0.48;              // altura de la boca (0 arriba, 1 pies)
uniform float wobble = 0.0;                // temblor de gelatina
uniform float breath = 0.0;                // respiración
uniform float time_s = 0.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform vec4 tint : source_color = vec4(1.0);

void vertex() {
	vec2 uv = UV;
	vec2 p = VERTEX;                        // x en [-w/2, w/2], y en [-h, 0] (pies en 0)
	float up = 1.0 - uv.y;                  // 0 en los pies, 1 arriba
	// respiración: el cuerpo se ensancha y sube un poco
	float br = breath * sin(time_s * 2.4);
	p.x *= 1.0 + br * 0.025 * up;
	p.y *= 1.0 + br * 0.02;
	// panza
	vec2 d = uv - belly_center;
	float k = smoothstep(0.42, 0.0, length(d * vec2(1.0, 1.25)));
	p += normalize(d + vec2(0.0001)) * k * belly * size * vec2(0.12, 0.09);
	// boca: la parte de arriba se levanta y gira hacia atrás
	float top = smoothstep(mouth_y + 0.04, mouth_y - 0.04, uv.y);
	float front = smoothstep(0.35, 0.95, uv.x);
	p.y -= top * jaw * size.y * 0.16 * (0.35 + front);
	p.x -= top * jaw * size.x * 0.03;
	// cabeza adelante / atrás
	float hk = smoothstep(0.62, 0.12, uv.y);
	p.x += hk * head * size.x * 0.14;
	// aplastar y estirar conservando volumen
	p.y *= squash;
	p.x *= 1.0 / sqrt(max(squash, 0.25));
	// inclinación (cizalla desde los pies)
	p.x += lean * up * size.y * 0.22;
	// temblor
	p.x += sin(time_s * 38.0 + uv.y * 9.0) * wobble * size.x * 0.035 * up;
	VERTEX = p;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	c.rgb *= tint.rgb;
	c.rgb = mix(c.rgb, flash_color.rgb * 1.8, flash);
	COLOR = c;
}
