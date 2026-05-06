shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D texture_albedo : source_color;
uniform vec4 ring_color = vec4(0.0, 0.5, 1.0, 1.0);
uniform float ring_width = 0.08;
uniform float glow_width = 0.15;
uniform float glow_intensity = 1.5;
uniform float ellipse_x = 0.75;
uniform float ellipse_y = 0.9;
uniform float noise_strength = 0.05;
uniform float noise_speed = 3;
uniform float noise_scale = 15;

// Hash function for noise
float hash(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

// Smooth value noise
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i + vec2(0,0)), hash(i + vec2(1,0)), u.x),
        mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), u.x),
        u.y
    );
}

// Two octaves of noise for more organic feel
float fbm(vec2 p) {
    return noise(p) * 0.6 + noise(p * 2.1 + vec2(5.2, 1.3)) * 0.4;
}

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;

    // Angle around the ellipse — used to animate noise along the ring
    float angle = atan(uv.y, uv.x);
    vec2 noise_uv = vec2(angle * noise_scale / 6.28318, TIME * noise_speed);
    float n = fbm(noise_uv) - 0.5; // Center around 0

    // Apply noise as a radial displacement
    vec2 displaced_uv = uv + normalize(uv) * n * noise_strength;

    // Ellipse distance with noise applied
    float dist = (displaced_uv.x * displaced_uv.x) / (ellipse_x * ellipse_x)
               + (displaced_uv.y * displaced_uv.y) / (ellipse_y * ellipse_y);

    // Discard outside glow radius
    float glow_edge = 1.0 + glow_width;
    if (dist > glow_edge) {
        discard;
    }

    // Inner portal viewport
    float inner_edge = 1.0 - ring_width;
    float inner_dist = (displaced_uv.x * displaced_uv.x) / ((ellipse_x * inner_edge) * (ellipse_x * inner_edge))
                     + (displaced_uv.y * displaced_uv.y) / ((ellipse_y * inner_edge) * (ellipse_y * inner_edge));

    if (inner_dist < 1.0) {
        // Inside: render viewport
        vec4 albedo_tex = texture(texture_albedo, SCREEN_UV);
        ALBEDO = albedo_tex.rgb;
    } 
	else {
        // Ring + glow zone
        // Hard ring opacity (full color)
        float ring_opacity = smoothstep(1.0, 1.0 - 0.02, dist) * smoothstep(inner_edge - 0.01, inner_edge + 0.01, sqrt(inner_dist));

        // Outer glow fades to transparent
        float glow_opacity = smoothstep(glow_edge, 1.0, dist);
        glow_opacity = 1.0 - glow_opacity;
        glow_opacity *= smoothstep(inner_edge, 1.0, dist);

      
        vec3 color = ring_color.rgb;
        float alpha = max(ring_opacity, glow_opacity * glow_intensity * 0.4);

        // Add a subtle brightness pulse using the noise value
        float pulse = fbm(vec2(TIME * noise_speed * 0.5, 0.0)) * 0.3 + 0.85;
        color *= pulse;
		if (alpha < 0.01) {
		    discard;
		}
		ALBEDO = color * alpha;
    }
}