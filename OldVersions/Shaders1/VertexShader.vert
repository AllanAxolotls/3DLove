extern mat4 WVP;
extern mat4 LightWVP;

attribute vec3 VertexNormal;

varying vec4 VaryingNormal;
varying vec3 LocalPos;
varying vec4 LightSpacePos;

vec4 position(mat4 transform_projection, vec4 Position){
    vec4 Transformed = WVP * Position;
    vec4 ScreenSpace = transform_projection * Transformed;

    LocalPos = vec3(Position.x, Position.y, Position.z);
    VaryingNormal = vec4(VertexNormal, 1.0f);

    LightSpacePos = LightWVP * Position; // Only required for shadow mapping

    return ScreenSpace;
}