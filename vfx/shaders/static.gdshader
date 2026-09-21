shader_type canvas_item;

uniform float amount = 40.0;
uniform float transparency : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	float a = fract(sin(dot(UV, vec2(12.9898, 78.233) * TIME)) * 438.5453) * 1.9;
	vec4 col = texture(TEXTURE, UV);
	
	// Calculate the static noise alpha
	float noise_alpha = pow(a, amount);
	
	// Clamp the noise alpha between 0.0 and 1.0 before applying it to the texture
	col.a *= clamp(noise_alpha, 0.0, 1.0);
	
	COLOR = col;
	
	// Now the transparency slider will smoothly scale down from a maximum of 1.0
	COLOR.a *= transparency; 
}