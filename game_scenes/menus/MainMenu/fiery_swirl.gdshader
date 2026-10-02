shader_type canvas_item;

// The speed of the horizontal flame movement (sway)
uniform float sway_speed : hint_range(0.1, 5.0) = 1.0; 
// How far the texture is displaced horizontally
uniform float sway_strength : hint_range(0.0, 0.05) = 0.01;
// Scales the noise to control the size of the waves/flickers
uniform float noise_scale : hint_range(1.0, 20.0) = 5.0;
// The time offset for this specific flame instance
uniform float time_offset : hint_range(0.0, 100.0) = 0.0;

// Controls the continuous rotation speed of the vortex
uniform float swirl_speed : hint_range(0.0, 5.0) = 1.5; 
// Controls how tightly the spiral winds inward based on distance
uniform float swirl_twists : hint_range(-10.0, 10.0) = 3.0; 
// The origin point of the swirl
uniform vec2 swirl_center = vec2(0.5, 0.5);

// NEW: Controls the overall transparency of the texture
uniform float alpha_multiplier : hint_range(0.0, 1.0) = 1.0;

// Simple noise function
float noise1(vec2 p, float t) { 
    float n = sin(p.x * 2.0 + t * sway_speed) * 0.5;
    n += sin(p.y * 5.0 + t * sway_speed * 1.5) * 0.3;
    return n;
}

void fragment() {
    float instance_time = TIME + time_offset;
    vec2 distorted_uv = UV;

    // 1. Calculate the base noise for the fiery sway
    float noise_val = noise1(UV * noise_scale, instance_time);

    // 2. Apply the original horizontal sway
    distorted_uv.x += noise_val * sway_strength;

    // 3. Calculate continuous fluid vortex
    vec2 offset = distorted_uv - swirl_center;
    float dist = length(offset);
    
    float angle = (instance_time * swirl_speed) - (dist * swirl_twists);
    angle += noise_val * 0.5; 
    
    float s = sin(angle);
    float c = cos(angle);
    
    vec2 swirled_offset = vec2(
        offset.x * c - offset.y * s,
        offset.x * s + offset.y * c
    );
    
    distorted_uv = swirl_center + swirled_offset;

    // 4. Sample the original texture
    vec4 color = texture(TEXTURE, distorted_uv);
    
    // 5. Apply the transparency multiplier
    color.a *= alpha_multiplier;

    COLOR = color;
}