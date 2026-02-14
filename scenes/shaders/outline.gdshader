shader_type canvas_item;

uniform vec4 light_color : source_color = vec4(0.83, 0.0, 0.141, 0.5);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.42, 0.8, 0.5); 
uniform bool active = true;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    
    if (active && col.a > 0.0) {
        // Sample surrounding pixels
        float top = texture(TEXTURE, UV + vec2(0.0, -TEXTURE_PIXEL_SIZE.y)).a;
        float left = texture(TEXTURE, UV + vec2(-TEXTURE_PIXEL_SIZE.x, 0.0)).a;
        float bottom = texture(TEXTURE, UV + vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a;
        float right = texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).a;

        // TOP-LEFT HIGHLIGHT: If there's no pixel above or to the left
        if (top < 0.1 || left < 0.1) {
            col.rgb = mix(col.rgb, light_color.rgb, light_color.a);
        }
        // BOTTOM-RIGHT SHADOW: If there's no pixel below or to the right
        else if (bottom < 0.1 || right < 0.1) {
            col.rgb = mix(col.rgb, shadow_color.rgb, shadow_color.a);
        }
    }
    
    COLOR = col;
}