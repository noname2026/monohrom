shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float strength : hint_range(0.0,   1.0) = 1.0;

void fragment() {
	vec3 original = texture(screen_texture, SCREEN_UV).rgb;
	float luminance = dot(original, vec3(0.2126, 0.7152, 0.0722));
	COLOR = vec4(mix(original, vec3(luminance), strength), 1.0);
}
