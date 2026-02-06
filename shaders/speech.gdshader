shader_type canvas_item;

uniform float amount_px : hint_range(0.0, 3.0) = 1.0;  // max pixel shift
uniform float speed : hint_range(0.0, 10.0) = 3.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

void fragment() {
	// texture pixel size (1/width, 1/height)
	vec2 px = TEXTURE_PIXEL_SIZE;

	// “cell” coords in pixel space
	vec2 pixel_pos = UV / px;

	// per-pixel random that animates over time (quantized time to avoid smear)
	float t = floor(TIME * speed);
	float r1 = hash(pixel_pos + t);
	float r2 = hash(pixel_pos + t + 17.0);

	// random direction in {-1, 0, 1} pixels
	vec2 shift = vec2(round(r1 * 2.0 - 1.0), round(r2 * 2.0 - 1.0));

	// scale by amount_px but keep it integer pixels
	shift *= round(amount_px);

	vec2 uv2 = UV + shift * px;

	COLOR = texture(TEXTURE, uv2) * COLOR;
}
