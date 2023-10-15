const int MAX_POINT_LIGHTS = 2;
const int MAX_DIR_LIGHTS = 3;
const int MAX_SPOT_LIGHTS = 2;

struct BaseLight {
    vec3 Color;
    float AmbientIntensity;
    float DiffuseIntensity;
};

struct DirLight {
    BaseLight Base;
    vec3 Direction;
};

struct Attenuation {
    float Constant;
    float Linear;
    float Exp;
};

struct PointLight {
    BaseLight Base;
    vec3 LocalPos;
    Attenuation Atten;
};

struct SpotLight {
    PointLight Base;
    vec3 Direction;
    float Cutoff; // cosine of angle
};


// Light Arrays
extern DirLight DirLights[MAX_DIR_LIGHTS];
extern PointLight PointLights[MAX_POINT_LIGHTS];
extern SpotLight SpotLights[MAX_SPOT_LIGHTS];

extern int TotalPointLights;
extern int TotalSpotLights;

DirLight MainDirLight = DirLights[0];

// Material
extern vec3 MaterialAmbientColor;
extern vec3 MaterialDiffuseColor;
extern vec3 MaterialSpecularColor;
extern float MaterialSpecularExponent;
extern float MaterialOpaque;

// Externs
extern vec3 CameraPos;
extern Image SpecularMap;
extern bool UseSpecularMap;
extern Image ShadowMap;
extern float RimLightPower;

extern bool CellShadingEnabled;
extern bool RimLightEnabled;

// Varyings
varying vec4 VaryingNormal;
varying vec3 LocalPos;
varying vec4 LightSpacePos;

float CalcRimLightFactor(vec3 PixelToCamera, vec3 Normal) {
    float RimFactor = dot(PixelToCamera, Normal);
    RimFactor = 1.0 - RimFactor;
    RimFactor = max(0.0, RimFactor);
    RimFactor = pow(RimFactor, RimLightPower);
    return RimFactor;
}

float CalcShadowFactor() {
    vec3 ProjCoords = LightSpacePos.xyz / LightSpacePos.w;
    vec2 UVCoords;
    // To Texture Space
    UVCoords.x = 0.5 * ProjCoords.x + 0.5;
    UVCoords.y = 0.5 * ProjCoords.y + 0.5;
    float z = 0.5 * ProjCoords.z + 0.5;
    float Depth = Texel(ShadowMap, UVCoords).x;

    float bias = 0.0025;

    if (Depth + bias > z)
        return 0.5;
    else
        return 1.0;
}

vec4 CalcLightInternal(BaseLight Light, vec3 LightDirection, vec3 Normal, float ShadowFactor){
    vec3 LocalAmbientColor = Light.Color * Light.AmbientIntensity * MaterialAmbientColor;

    // Cool soft colors
    //return vec4(-LightDirection * 0.5 + 0.5, 0);

    float DiffuseFactor = dot(Normal, -LightDirection * 0.5 + 0.5);
    vec3 LocalDiffuseColor = vec3(0, 0, 0);
    vec3 LocalSpecularColor = vec3(0, 0, 0);
    vec3 RimColor = vec3(0, 0, 0);

    if (DiffuseFactor > 0){
        LocalDiffuseColor = Light.Color * Light.DiffuseIntensity * MaterialDiffuseColor * DiffuseFactor;

        vec3 PixelToCamera = normalize(CameraPos - LocalPos);
        vec3 LightReflect = normalize(reflect(LightDirection, Normal));
        float SpecularFactor = dot(PixelToCamera, LightReflect);

        if (!CellShadingEnabled && (SpecularFactor > 0)) {
            // texture is grayscale
            if (UseSpecularMap == true) {
                //SpecularFactor = Texel(SpecularMap, VaryingTexCoord).r * 255.0;
            }
            else {
                // No Texture
                SpecularFactor = pow(SpecularFactor, MaterialSpecularExponent);
                LocalSpecularColor = Light.Color * MaterialSpecularColor * SpecularFactor;
            }
        }

        if (RimLightEnabled) {
            float RimFactor = CalcRimLightFactor(PixelToCamera, Normal);
            RimColor = LocalDiffuseColor * RimFactor;
        }
    }

    return vec4(LocalAmbientColor + ShadowFactor * (LocalDiffuseColor + LocalSpecularColor + RimColor), 0);
}

vec4 CalcPointLight(PointLight l, vec3 Normal) {
    vec3 LightDirection = LocalPos - l.LocalPos;
    float Distance = length(LightDirection);
    LightDirection = normalize(LightDirection);

    float ShadowFactor = CalcShadowFactor();
    vec4 Color = CalcLightInternal(l.Base, LightDirection, Normal, ShadowFactor);
    float LightAttenuation = l.Atten.Constant +
                        l.Atten.Linear * Distance +
                        l.Atten.Exp * Distance * Distance;
    return Color / LightAttenuation;
}

vec4 CalcDirectionalLight(vec3 Normal) {
    float ShadowFactor = 1.0;
    return CalcLightInternal(MainDirLight.Base, MainDirLight.Direction, Normal, ShadowFactor);
}

vec4 CalcSpotLight(SpotLight l, vec3 Normal) {
    // Cool Normal Red colors
    //return vec4(Normal.x, 0, 0, 0);

    vec3 LightToPixel = normalize(LocalPos - l.Base.LocalPos);
    float SpotFactor = dot(LightToPixel, l.Direction);

    if (SpotFactor > l.Cutoff) {
        vec4 Color = CalcPointLight(l.Base, Normal);
        float SpotLightIntensity = (1.0 - (1.0 - SpotFactor) / (1.0 - l.Cutoff));
        return Color * SpotLightIntensity;
    }
    else { 
        return vec4(0,0,0,0);
    }
}

vec4 effect(vec4 Color, Image image, vec2 uvs, vec2 screen_coords) {
    vec3 Normal = vec3(normalize(VaryingNormal));
    vec4 TotalLight = CalcDirectionalLight(Normal);

    for (int i = 0; i < TotalPointLights; i++) {
        TotalLight += CalcPointLight(PointLights[i], Normal);
    }

    for (int i = 0; i < TotalSpotLights; i++) {
        TotalLight += CalcSpotLight(SpotLights[i], Normal);
    }

    vec4 Result = Texel(image, uvs) * TotalLight;
    return vec4(vec3(Result), MaterialOpaque);
}