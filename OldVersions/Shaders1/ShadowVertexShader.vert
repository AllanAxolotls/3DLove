extern mat4 WVP;

vec4 position(mat4 transform_projection, vec4 Position) {
    return transform_projection * (WVP * Position);
}