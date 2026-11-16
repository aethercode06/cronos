shader_type spatial;
// Bancos de niebla a ras de suelo: tarjetas que miran a la cámara (giran solo en Y), con ruido que se mueve
// despacio, bordes suaves, se funden con lo que tocan (profundidad) y desaparecen cerca de la cámara.
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled, specular_disabled;
uniform sampler2D ruido : repeat_enable, filter_linear_mipmap;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec4 color : source_color = vec4(0.52, 0.56, 0.64, 1.0);
uniform float densidad = 0.32;
uniform float luz_luna = 0.18;
varying float semilla;

void vertex() {
	semilla = fract(MODEL_MATRIX[3].x * 0.137 + MODEL_MATRIX[3].z * 0.071);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 uv = UV * vec2(0.7, 0.45) + vec2(semilla * 3.7 + TIME * 0.012, semilla * 1.3 + TIME * 0.004);
	float n = texture(ruido, uv).r * 0.65 + texture(ruido, uv * 2.3 - vec2(TIME * 0.02, 0.0)).r * 0.35;
	n = smoothstep(0.28, 0.85, n);
	// bordes: redondeado a los lados, más denso abajo y deshilachado arriba
	float lado = smoothstep(0.0, 0.3, UV.x) * smoothstep(1.0, 0.7, UV.x);
	float alto = smoothstep(0.0, 0.18, 1.0 - UV.y) * smoothstep(0.0, 0.65, UV.y);
	// fundido con la escena (no corta en seco contra el suelo, troncos o paredes)
	float d = texture(depth_tex, SCREEN_UV).r;
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV, d) * 2.0 - 1.0;
	#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, d);
	#endif
	vec4 vp = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float escena = -vp.z / vp.w;
	float frag = -VERTEX.z;
	float suave = clamp((escena - frag) / 1.8, 0.0, 1.0);
	float cerca = clamp((frag - 0.8) / 3.5, 0.0, 1.0);
	ALBEDO = color.rgb;
	EMISSION = color.rgb * luz_luna;
	ALPHA = n * lado * alto * suave * cerca * densidad;
}
