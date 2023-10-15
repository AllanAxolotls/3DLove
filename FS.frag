// Material Data
extern vec3 Ka;
extern vec3 Kd;
extern vec3 Ks;
extern float Ns;
extern float d;

varying vec3 VarNormal;
varying vec3 LocalPos;
varying vec4 LightSpacePos;

extern vec3 CameraLocalPos;
extern bool shaded;
extern bool show_normal;
extern bool UseDepthMap;
extern Image DepthMap;

extern float RimLightPower;
extern bool RimLightEnabled;

extern int TotalBaseLights;
extern int TotalDirLights;
extern int TotalPointLights;
extern int TotalSpotLights;

const int MaxBaseLights = 3;
const int MaxDirLights = 3;
const int MaxPointLights = 3;
const int MaxSpotLights = 3;

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
    float Quadratic;
};

struct PointLight {
    BaseLight Base;
    vec3 Position;
    Attenuation Atten;
};

struct SpotLight {
    PointLight PointBase;
    vec3 Direction;
    float Cutoff;
};

extern BaseLight BaseLights[MaxBaseLights];
extern DirLight DirLights[MaxDirLights];
extern PointLight PointLights[MaxPointLights];
extern SpotLight SpotLights[MaxSpotLights];

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
    UVCoords.x = (0.5 * ProjCoords.x) + 0.5;
    UVCoords.y = (0.5 * ProjCoords.y) + 0.5;
    float z = (0.5 * ProjCoords.z) + 0.5;
    float Depth = Texel(DepthMap, UVCoords).r;
    float bias = 0.0025;

    if (Depth + bias < z)
        return 0.5;
    else
        return 1.0;
}

vec3 CalcLightInternal(BaseLight l, vec3 Direction, vec3 Normal, float ShadowFactor) {
    vec3 AmbientColor = l.Color * l.AmbientIntensity * Ka;
    vec3 DiffuseColor = vec3(0, 0, 0);
    vec3 SpecularColor = vec3(0, 0, 0);
    vec3 RimColor = vec3(0, 0, 0);

    float DiffuseFactor = dot(normalize(Normal), -Direction);
    if (DiffuseFactor > 0) {
        DiffuseColor = l.Color * l.DiffuseIntensity * Kd * DiffuseFactor; 

        // If DiffuseFactor isn't greater than 0, the light doesn't reach so specular can't exist
        vec3 PixelToCamera = normalize(CameraLocalPos - LocalPos);
        vec3 LightReflect = normalize(reflect(Direction, Normal));
        float SpecularFactor = dot(PixelToCamera, LightReflect);

        if (SpecularFactor > 0 && Ns > 0) {
            //float SpecularExponent = Texel(map_Ks, uvs).r * 255.0;
            //SpecularFactor = pow(SpecularFactor, SpecularExponent);

            SpecularFactor = pow(SpecularFactor, Ns);
            SpecularColor = l.Color * Ks * SpecularFactor;
        }

        if (RimLightEnabled) {
            float RimFactor = CalcRimLightFactor(PixelToCamera, Normal);
            RimColor = DiffuseColor * RimFactor;
        }
    }

    return AmbientColor + ShadowFactor * (DiffuseColor + SpecularColor + RimColor);
}

vec3 CalcDirLight(DirLight l, vec3 Normal) {
    float ShadowFactor = 1.0;
    return CalcLightInternal(l.Base, l.Direction, Normal, ShadowFactor);
}

vec3 CalcPointLight(PointLight l, vec3 Normal) {
    vec3 LightDirection = LocalPos - l.Position;
    float Distance = length(LightDirection);
    LightDirection = normalize(LightDirection);

    vec3 Color = CalcLightInternal(l.Base, LightDirection, Normal, CalcShadowFactor());
    float Atten = l.Atten.Constant +
                        l.Atten.Linear * Distance +
                        l.Atten.Quadratic * Distance * Distance;
    return Color / Atten;
}

vec3 CalcSpotLight(SpotLight l, vec3 Normal) {
    vec3 LightToPixel = normalize(LocalPos - l.PointBase.Position);
    float SpotFactor = dot(LightToPixel, l.Direction);

    if (SpotFactor > l.Cutoff) {
        vec3 Color = CalcPointLight(l.PointBase, Normal);
        float SpotLightIntensity = (1.0 - (1.0 - SpotFactor) / (1.0 - l.Cutoff));
        return Color * SpotLightIntensity;
    }
    else {
        return vec3(0, 0, 0);
    }
}

vec4 effect(vec4 Color, Image image, vec2 uvs, vec2 screen_coords) {
    vec3 TexelColor = vec3( Texel(image, uvs) ) * vec3(Color);
    //vec4 DepthColor = vec4(1, 1, 1, 1);
    vec3 Normal = normalize(VarNormal);

    if (shaded == false) return vec4(TexelColor, d);
    if (show_normal == true) return vec4(Normal, 1.0);

    if (UseDepthMap == true) {
        //DepthColor = Texel(DepthMap, uvs);
        //return Texel(DepthMap, uvs);
    } else {
        return vec4(1, 1, 1, 1);
    }

    vec3 TotalLight = vec3(0, 0, 0);

    for (int i = 0; i < TotalBaseLights; i++) {
        TotalLight += CalcLightInternal(BaseLights[i], vec3(0,-1,0), Normal, 1.0);
    }

    for (int i = 0; i < TotalDirLights; i++) {
        TotalLight += CalcDirLight(DirLights[i], Normal);
    }

    for (int i = 0; i < TotalPointLights; i++) {
        TotalLight += CalcPointLight(PointLights[i], Normal);
    }

     for (int i = 0; i < TotalSpotLights; i++) {
        TotalLight += CalcSpotLight(SpotLights[i], Normal);
    }

    return vec4(TexelColor * TotalLight, d);
}