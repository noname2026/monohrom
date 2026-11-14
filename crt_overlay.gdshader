shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float noise_amount : hint_range(0.0, 0.2) = 0.045;
uniform float scanline_amount : hint_range(0.0, 0.4) = 0.08;
uniform float vignette_amount : hint_range(0.0, 1.0) = 0.55;
uniform float glitch : hint_range(0.0, 1.0) = 0.0;
uniform float aberration : hint_range(0.0, 4.0) = 0.6;


float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}


void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 centered = uv - vec2(0.5);
	float radius_sq = dot(centered, centered);

	// Лёгкая выпуклость старой ЭЛТ-трубки.
	uv = vec2(0.5) + centered * (1.0 + radius_sq * 0.035);

	float t = TIME;
	float band = floor(uv.y * 160.0);
	float jitter = (rand(vec2(band, floor(t * 12.0))) - 0.5) * 0.0016 * (1.0 + glitch * 20.0);
	uv.x += jitter;
	uv.y += sin(uv.x * 8.0 + t * 0.7) * 0.0004;
	uv = clamp(uv, vec2(0.0), vec2(1.0));

	// Хроматическое расщепление — почти незаметное, пока не начнётся сбой.
	float shift = aberration * (0.25 + glitch * 3.0) * 0.0015;
	vec3 col;
	col.r = texture(screen_texture, uv + vec2(shift, 0.0)).r;
	col.g = texture(screen_texture, uv).g;
	col.b = texture(screen_texture, uv - vec2(shift, 0.0)).b;

	// Строчная развёртка.
	float scan = 0.5 + 0.5 * sin(uv.y / max(SCREEN_PIXEL_SIZE.y, 0.0001) * 3.14159);
	col *= 1.0 - scan * scanline_amount;

	// Зерно плёнки / шум сенсора.
	float grain = rand(uv * vec2(1920.0, 1080.0) + fract(t) * 137.0);
	col += (grain - 0.5) * noise_amount;

	// Виньетка.
	float vig = smoothstep(0.95, 0.22, length(centered * vec2(1.0, 0.92)));
	col *= mix(1.0, vig, vignette_amount);

	// Дыхание лампы.
	float flicker = 0.985 + 0.015 * sin(t * 47.0) + 0.01 * sin(t * 13.0);
	col *= flicker;

	COLOR = vec4(col, 1.0);
}
