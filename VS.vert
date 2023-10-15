extern mat4 WVP;
extern mat4 LightWVP;

attribute vec3 VertexNormal;

varying vec3 VarNormal;
varying vec3 LocalPos;
varying vec4 LightSpacePos;

vec4 position(mat4 transform_projection, vec4 Position) {
    vec4 Transform = WVP * Position;
    vec4 ScreenSpace = transform_projection * Transform;

    VarNormal = VertexNormal;
    LocalPos = vec3(Position);

    //LightSpacePos = transform_projection * (LightWVP * Position);
    //LightSpacePos = vec4(LightSpacePos.xyz / LightSpacePos.w, 1.0);
    LightSpacePos = LightWVP * Position;

    return ScreenSpace;
}