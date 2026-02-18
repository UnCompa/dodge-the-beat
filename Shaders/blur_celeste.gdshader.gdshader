shader_type canvas_item;

uniform float blur_size : hint_range(0.0, 0.01) = 0.003;  // Ajusta para más/menos blur
uniform float celeste_mix : hint_range(0.0, 1.0) = 0.6;   // Intensidad celeste

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    
    // Blur simple (kernel 3x3 optimizado)
    vec4 sum = tex * 0.2;
    sum += texture(TEXTURE, UV + vec2(-blur_size, 0.0)) * 0.2;
    sum += texture(TEXTURE, UV + vec2(blur_size, 0.0)) * 0.2;
    sum += texture(TEXTURE, UV + vec2(0.0, -blur_size)) * 0.2;
    sum += texture(TEXTURE, UV + vec2(0.0, blur_size)) * 0.2;
    
    // Tint celeste + glow
    vec3 celeste = vec3(0.4, 0.9, 1.0);
    COLOR = mix(sum, vec4(celeste, 1.0), celeste_mix);
    COLOR.a *= tex.a;  // Mantiene transparencia
}