shader_type canvas_item;

uniform vec4 light_color : source_color = vec4(0.83, 0.0, 0.141, 0.8);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.42, 0.8, 0.8); 
uniform float pulse_speed : hint_range(0.0, 10.0) = 4.0;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    
    // Pulse calculation for that "unstable energy" look
    float pulse = (sin(TIME * pulse_speed) * 0.2) + 0.3;
    
    // Pixel-perfect neighbor sampling
    float top = texture(TEXTURE, UV + vec2(0.0, -TEXTURE_PIXEL_SIZE.y)).a;
    float left = texture(TEXTURE, UV + vec2(-TEXTURE_PIXEL_SIZE.x, 0.0)).a;
    float bottom = texture(TEXTURE, UV + vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a;
    float right = texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).a;

    // Output logic
    if (col.a > 0.1) {
        // TOP-LEFT: Red Energy
        if (top < 0.1 || left < 0.1) {
            COLOR = vec4(light_color.rgb, light_color.a * pulse);
        }
        // BOTTOM-RIGHT: Blue Energy
        else if (bottom < 0.1 || right < 0.1) {
            COLOR = vec4(shadow_color.rgb, shadow_color.a * pulse);
        }
        // HIDE THE BODY
        else {
            COLOR = vec4(0.4, 0.2, 0.4, 0.3);
        }
    } else {
        COLOR = vec4(0.0);
    }
}