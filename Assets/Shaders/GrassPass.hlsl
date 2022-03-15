#include "Utill.hlsl"

struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT;
    //float2 uv           : TEXCOORD0;
    float4 color        : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv                       : TEXCOORD0;
    float4 positionWSAndFogFactor   : TEXCOORD1; // xyz: positionWS, w: vertex fog factor
    half3  normalWS                 : TEXCOORD2;
    half3 tangentWS                 : TEXCOORD3;
    float4 positionOS : TEXCOORD4;
    float4 color : COLOR;

    // #ifdef _MAIN_LIGHT_SHADOWS
    // float4 shadowCoord              : TEXCOORD6; // compute shadow coord per-vertex for the main light
    // #endif

    float4 positionCS               : SV_POSITION;
};

//Properties
float _Height;
float _Base;

float4 _Tint;
float4 _Darker;
float _LightPower;
float _TPower;
float _ShadowPower;
float _AlphaCutoff;

//sampler2D _BaseMap;
sampler2D _WindDistortionMap;
float3 _WindFrequency;
float _WindStrength;

float _MinHeight;
float _MaxHeight;

float3 _DetailPos;
float _DisCutoff;

//VERTEX PASS
Varyings Vertex(Attributes input)
{
    Varyings output;

    output.color = input.color;

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

    //output.uv = TRANSFORM_TEX(input.uv, _BaseMap);

    output.positionWSAndFogFactor = float4(vertexInput.positionWS, fogFactor);
    output.positionCS = vertexInput.positionCS;
    output.positionOS = input.positionOS;

    output.normalWS = vertexNormalInput.normalWS;
    output.tangentWS = vertexNormalInput.tangentWS;

    // #ifdef _NORMALMAP
    //     output.bitangentWS = vertexNormalInput.bitangentWS;
    // #endif

    // #ifdef _MAIN_LIGHT_SHADOWS
    //     output.shadowCoord = GetShadowCoord(vertexInput);
    // #endif

    return output;
}

[maxvertexcount(6)]
void Geometry(triangle Varyings input[3], inout TriangleStream<Varyings> outStream)
{

    if (input[0].color.g < 0.1f && input[0].color.r > 0.9f)
        return;

    float3 basePos = (input[0].positionWSAndFogFactor.xyz + input[1].positionWSAndFogFactor.xyz + input[2].positionWSAndFogFactor.xyz) / 3;
    float baseFog = (input[0].positionWSAndFogFactor.w + input[1].positionWSAndFogFactor.w + input[2].positionWSAndFogFactor.w) / 3;

    float dis = mag(TransformWorldToHClip(basePos));
    if (dis > _DisCutoff) { return; }

    float2 tp  = input[0].positionWSAndFogFactor.xz;
    tp.x = fmod(tp.x, 10);
    tp.y = fmod(tp.y, 10);

    float2 uv = (tp * _Time.xy * _WindFrequency);
    // uv.x = fmod(uv.x, 1);
    // uv.y = fmod(uv.y, 1);

    float4 windSample = tex2Dlod(_WindDistortionMap, float4(uv, 0, 0)) * _WindStrength;

    float3 rotatedNormalZ = mul(input[0].normalWS, RotZ(windSample.x));

    float3 rotatedNormal = mul(rotatedNormalZ, RotX(windSample.y));

    float randomHeight = rand(input[0].positionWSAndFogFactor.xyz * 2.238293f);

    Varyings o = input[0];

    float3 rotatedTangent = normalize(mul(o.tangentWS, RotY(rand(o.positionWSAndFogFactor.xyz) * 90)));
    float randH = rand(rotatedTangent) * 0.15;
    float3 oPos = (basePos - rotatedTangent *_Base);
    o.positionCS = TransformWorldToHClip(oPos);
    o.positionWSAndFogFactor = float4(oPos, baseFog);

    Varyings o2 = input[0];
    float3 o2Pos = (basePos + rotatedTangent * _Base);
    o2.positionCS = TransformWorldToHClip(o2Pos);
    o2.positionWSAndFogFactor = float4(o2Pos, baseFog);

    Varyings o3 = input[0];
    float3 o3Pos = (basePos + rotatedTangent * _Base + rotatedNormal*clamp(_Height* randomHeight,_MinHeight,_MaxHeight));
    o3.positionCS = TransformWorldToHClip(o3Pos);
    o3.positionWSAndFogFactor = float4(o3Pos, baseFog);

    Varyings o4 = input[0];
    float3 o4Pos = (basePos - rotatedTangent * _Base + rotatedNormal * clamp(_Height * randomHeight, _MinHeight, _MaxHeight));
    o4.positionCS = TransformWorldToHClip(o4Pos);
    o4.positionWSAndFogFactor = float4(o4Pos, baseFog);

    float3 newNormal = mul(rotatedTangent, RotY(PI / 2));

    o4.uv = TRANSFORM_TEX(float2(0, 1), _BaseMap);
    o3.uv = TRANSFORM_TEX(float2(1, 1), _BaseMap);
    o2.uv = TRANSFORM_TEX(float2(1, 0), _BaseMap);
    o.uv = TRANSFORM_TEX(float2(0, 0), _BaseMap);

    o.normalWS = newNormal;
    o2.normalWS = newNormal;
    o3.normalWS = newNormal;
    o4.normalWS = newNormal;

    outStream.Append(o4);
    outStream.Append(o3);
    outStream.Append(o);

    outStream.RestartStrip();

    outStream.Append(o3);
    outStream.Append(o2);
    outStream.Append(o);

    outStream.RestartStrip();

}

half4 Fragment(Varyings input, bool vf : SV_IsFrontFace) : SV_Target
{
    half3 normalWS = input.normalWS;

    normalWS = normalize(normalWS);

    if (vf == true)
    {
        normalWS = -normalWS;
    }

    float3 positionWS = input.positionWSAndFogFactor.xyz;

    half3 color = (0, 0, 0);

    Light mainLight;

    float4 shadowCoord = TransformWorldToShadowCoord(positionWS);

    mainLight = GetMainLight(shadowCoord);

    float3 normalLight = LightingLambert(mainLight.color, mainLight.direction, normalWS) * _LightPower;
    float3 inverseNormalLight = LightingLambert(mainLight.color, mainLight.direction, -normalWS) * _TPower;

    color = _Tint + normalLight + inverseNormalLight;
    color = lerp(color, _Darker, 1 - input.uv.y);

    color = lerp(_Darker, color, clamp(mainLight.shadowAttenuation + _ShadowPower, 0, 1));

    //
    // float fogFactor = input.positionWSAndFogFactor.w;
    //
    // color = MixFog(color, fogFactor);
    //
    float a = _BaseMap.Sample(sampler_BaseMap, input.uv).a;

    clip(a - _AlphaCutoff);


    return half4(color, 1);
}
