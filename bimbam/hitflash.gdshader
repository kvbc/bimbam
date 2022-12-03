shader_type canvas_item;

uniform bool is_on = false;

void fragment () {
	vec4 color = texture(TEXTURE, UV);
	COLOR = color;
	if (is_on) {
		if (color.a >= 0.5) {
			COLOR = vec4(255, 255, 255, 1.0);
		}
	}
}