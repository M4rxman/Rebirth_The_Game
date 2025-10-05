shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform vec4 BaseColor : source_color = vec4(1.0, 0.9, 0.4, 1.0);
uniform float ShineStrength = 1.5;
uniform float WobbleSpeed   = 2.0;
uniform float WobbleAmount  = 0.05;
uniform float GlowSpeed     = 2.5;
uniform float GlowIntensity = 1.0;
uniform float FresnelPower   = 2.0;
uniform float FresnelStrength= 1.0;

varying float wobble_val;

void vertex() {
    float wobble = sin(TIME * WobbleSpeed + VERTEX.x * 3.0 + VERTEX.z * 3.0);
    // move along surface normal (no self-clipping)
    VERTEX += NORMAL * wobble * WobbleAmount;
    wobble_val = wobble;
}

void fragment() {
    float glow = 0.5 + 0.5 * sin(TIME * GlowSpeed + wobble_val);
    vec3 color = BaseColor.rgb * (1.0 + glow * GlowIntensity);

    float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), FresnelPower) * FresnelStrength;

    ALBEDO   = color;
    EMISSION = color * (glow * 0.8 + fresnel * ShineStrength);
    ALPHA    = BaseColor.a;
}
