shader_type canvas_item;
// Destello al recibir un golpe (Aether Engine)
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	c.rgb *= tint.rgb;
	c.rgb = mix(c.rgb, flash_color.rgb * 1.6, flash);
	COLOR = c;
}
