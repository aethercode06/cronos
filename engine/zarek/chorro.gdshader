shader_type spatial;
// Lámina de agua que cae por el borde de una taza de la fuente: vetas que bajan deprisa, más transparente arriba
// y espumosa abajo, con brillo de Fresnel.
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform sampler2D ruido : filter_linear_mipmap, repeat_enable;
uniform vec3 color : source_color = vec3(0.62, 0.7, 0.76);
uniform float velocidad = 1.6;
void fragment() {
	vec2 uv = vec2(UV.x * 6.0, UV.y * 0.8 - TIME * velocidad);
	float v = texture(ruido, uv).r * 0.7 + texture(ruido, uv * vec2(2.3, 1.4) + vec2(0.3, -TIME * 0.7)).r * 0.3;
	float vetas = smoothstep(0.35, 0.75, v);
	float abajo = smoothstep(0.55, 1.0, UV.y);
	float fres = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.0);
	ALBEDO = mix(color, vec3(0.85, 0.88, 0.9), abajo * 0.6 + vetas * 0.25);
	ROUGHNESS = 0.08;
	SPECULAR = 0.7;
	ALPHA = clamp((0.18 + vetas * 0.45 + abajo * 0.35 + fres * 0.3) * smoothstep(0.0, 0.06, UV.y), 0.0, 0.9);
}
