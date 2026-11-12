// Piel y ropa de Elena: textura del cuerpo + capa de expresión facial (2.º UV) con fundido entre dos caras.
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap;
uniform sampler2D mr_tex : hint_default_white, filter_linear_mipmap;
uniform float usar_normal = 0.0;
uniform sampler2D cara_a : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D cara_b : source_color, filter_linear_mipmap, repeat_disable;
uniform float mezcla : hint_range(0.0, 1.0) = 0.0;
uniform float rugosidad = 0.88;
uniform float brillo = 0.05;
uniform float ojos_brillo = 0.0;

void fragment() {
	// el atlas de TRELLIS tiene islas muy finas: con mipmaps altos se mezclan con el pelo y salen rayas negras,
	// así que se limita el nivel de detalle mínimo
	vec2 tam = vec2(textureSize(albedo_tex, 0));
	float lod = 0.5 * log2(max(dot(dFdx(UV * tam), dFdx(UV * tam)), dot(dFdy(UV * tam), dFdy(UV * tam))));
	vec3 c = textureLod(albedo_tex, UV, clamp(lod, 0.0, 1.0)).rgb;
	float lum0 = dot(c, vec3(0.3, 0.59, 0.11));
	// la textura de TRELLIS viene con la luz «horneada» y muy clara: se oscurece y ensucia un poco
	c = pow(c, vec3(1.3)) * vec3(0.74, 0.71, 0.66);
	vec2 f = UV2;
	float dentro = step(0.0, f.x) * step(f.x, 1.0) * step(0.0, f.y) * step(f.y, 1.0);
	vec4 a = texture(cara_a, f);
	vec4 b = texture(cara_b, f);
	vec4 cara = mix(a, b, mezcla);
	// mechones de pelo delante de la frente: no se les pinta la cara
	float k = cara.a * dentro * mix(1.0, smoothstep(0.03, 0.1, lum0), smoothstep(0.5, 0.58, f.y));
	ALBEDO = mix(c, cara.rgb, k);
	float r = texture(mr_tex, UV).g;
	ROUGHNESS = mix(clamp(r * 1.05, 0.55, 1.0) * rugosidad / 0.88, 0.6, k);
	NORMAL_MAP = mix(vec3(0.5, 0.5, 1.0), texture(normal_tex, UV).rgb, usar_normal * (1.0 - k * 0.6));
	NORMAL_MAP_DEPTH = 1.0;
	SPECULAR = 0.35;
	// ojos: zona de los ojos de la capa facial (para que brillen en la oscuridad si hace falta)
	float ojo = dentro * smoothstep(0.07, 0.03, min(distance(f, vec2(0.381, 0.546)), distance(f, vec2(0.610, 0.546))));
	EMISSION = ALBEDO * brillo + vec3(1.0, 0.95, 0.85) * ojo * ojos_brillo * k;
}
