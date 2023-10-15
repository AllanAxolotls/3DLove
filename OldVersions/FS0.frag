struct BaseLight {
    vec3 Color;
    float AmbientIntensity;
};

struct DirLight {
    vec3 Color;
    vec3 Direction;
    float AmbientIntensity;
    float DiffuseIntensity;
};

// Light Arrays
extern BaseLight BaseLights[1];
extern DirLight DirLights[1];

// Material
extern vec3 MaterialAmbientColor;
extern vec3 MaterialDiffuseColor;
extern vec3 MaterialSpecularColor;
extern float MaterialSpecularExponent;
extern float MaterialOpaque;

extern vec3 CameraPos;

varying vec4 VaryingNormal;
varying vec3 LocalPos;

vec4 effect(vec4 Color, Image image, vec2 uvs, vec2 screen_coords){
    DirLight gLight = DirLights[0];

    vec3 Normal = vec3(normalize(VaryingNormal));
    vec3 LocalAmbientColor = gLight.Color * gLight.AmbientIntensity * MaterialAmbientColor;

    float DiffuseFactor = dot(normalize(Normal), -gLight.Direction);
    vec3 LocalDiffuseColor = vec3(0, 0, 0);
    vec3 LocalSpecularColor = vec3(0, 0, 0);

    if (DiffuseFactor > 0){
        LocalDiffuseColor = gLight.Color * gLight.DiffuseIntensity * MaterialDiffuseColor * DiffuseFactor;

        vec3 PixelToCamera = normalize(CameraPos - LocalPos);
        vec3 LightReflect = normalize(reflect(gLight.Direction, Normal));
        float SpecularFactor = dot(PixelToCamera, LightReflect);

        if (SpecularFactor > 0) {
            // texture is grayscale
            //float SpecularExponent = Texel(SpecularTexture, uvs).r * 255.0;
            SpecularFactor = pow(SpecularFactor, MaterialSpecularExponent);
            LocalSpecularColor = gLight.Color * MaterialSpecularColor * SpecularFactor;
        }
    }

    return Texel(image, uvs) * clamp(vec4(LocalAmbientColor + LocalDiffuseColor + LocalSpecularColor, MaterialOpaque), 0, 1);
}