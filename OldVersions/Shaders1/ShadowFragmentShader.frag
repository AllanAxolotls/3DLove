vec4 effect(vec4 Color, Image image, vec2 uvs, vec2 screen_coords) {
    float Depth = Texel(image, uvs).x;
    Depth = 1.0 - (1.0 - Depth) * 25.0;
    return vec4(Depth);
}  