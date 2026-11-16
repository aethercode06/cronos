shader_type spatial;
// Tambor redondo de la torre: ladrillo mapeado por UV. La parte del cilindro que cae dentro de la casa no se dibuja
// (dentro está la sala cuadrada de la torre con sus paredes; antes el cilindro tapaba puertas sin tener colisión).
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rough_tex : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform vec3 color : source_color = vec3(0.5, 0.48, 0.44);
uniform vec2 uv_escala = vec2(8.5, 4.4);
uniform vec4 casa = vec4(0.0);   // x, z, ancho, fondo de la planta de la casa (en metros)
varying vec3 mundo;
void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	UV *= uv_escala;
}
void fragment() {
	if (mundo.x > casa.x + 0.12 && mundo.x < casa.x + casa.z - 0.12 && mundo.z > casa.y + 0.12 && mundo.z < casa.y + casa.w - 0.12) {
		discard;
	}
	ALBEDO = texture(albedo_tex, UV).rgb * color;
	NORMAL_MAP = texture(normal_tex, UV).rgb;
	ROUGHNESS = texture(rough_tex, UV).r;
}
