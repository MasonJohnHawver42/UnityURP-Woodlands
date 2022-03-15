// MIT License

// Copyright (c) 2021 NedMakesGames

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#ifndef GPE_INC
#define GPE_INC


#include "Utill.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct Attributes {
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;

    float4 color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct TessellationFactors {
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

struct TessellationControlPoint {
    float3 positionWS : INTERNALTESSPOS;
    float3 normalWS : NORMAL;
    float3 tangentWS : TANGENT;

    float4 positionCS : TEXCOORD0;

    float4 color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Interpolators {
    float3 normalWS                 : TEXCOORD0;
    float3 positionWS               : TEXCOORD1;
    float3 tangentWS                : TEXCOORD2;
    float2 uv                       : TEXCOORD4;

    float4 color                    : COLOR;
    float4 positionCS               : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};


//Properties

// CBUFFER_START(UnityPerMaterial)
//     float3 _FactorEdge1;
//     float _FactorEdge2;
//     float _FactorEdge3;
//     float _FactorInside;
//
//     float _Height;
//     float _Base;
//     float _Tint;
// CBUFFER_END

float3 _FactorEdge1;
float _FactorEdge2;
float _FactorEdge3;
float _FactorInside;

float _Height;
float _Base;

//sampler2D _BaseMap;
sampler2D _WindDistortionMap;


float3 GetViewDirectionFromPosition(float3 positionWS) {
    return normalize(GetCameraPositionWS() - positionWS);
}

float4 GetShadowCoord(float3 positionWS, float4 positionCS) {
    // Calculate the shadow coordinate depending on the type of shadows currently in use
#if SHADOWS_SCREEN
    return ComputeScreenPos(positionCS);
#else
    return TransformWorldToShadowCoord(positionWS);
#endif
}

TessellationControlPoint Vertex(Attributes input) {
    TessellationControlPoint output;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    output.positionWS = vertexInput.positionWS;
    output.positionCS = vertexInput.positionCS;
    output.normalWS = vertexNormalInput.normalWS;
    output.tangentWS = vertexNormalInput.tangentWS;

    output.color = input.color;

    return output;
}

// The patch constant function runs once per triangle, or "patch"
// It runs in parallel to the hull function
TessellationFactors PatchConstantFunction(
    InputPatch<TessellationControlPoint, 3> patch) {
    UNITY_SETUP_INSTANCE_ID(patch[0]); // Set up instancing
    // Calculate tessellation factors
    TessellationFactors f;

    if (ShouldClipPatch(patch[0].positionCS, patch[1].positionCS, patch[2].positionCS, 2500.0, 0.0)) {
      f.edge[0] = f.edge[1] = f.edge[2] = f.inside = 0; // Cull the patch
    } else {
      f.edge[0] = _FactorEdge1.x;
      f.edge[1] = _FactorEdge2;
      f.edge[2] = _FactorEdge3;
      f.inside = _FactorInside;
    }

    return f;
}

// The hull function runs once per vertex. You can use it to modify vertex
// data based on values in the entire triangle
[domain("tri")] // Signal we're inputting triangles
[outputcontrolpoints(3)] // Triangles have three points
[outputtopology("triangle_cw")] // Signal we're outputting triangles
[patchconstantfunc("PatchConstantFunction")] // Register the patch constant function
// Select a partitioning mode based on keywords
#if defined(_PARTITIONING_INTEGER)
[partitioning("integer")]
#elif defined(_PARTITIONING_FRAC_EVEN)
[partitioning("fractional_even")]
#elif defined(_PARTITIONING_FRAC_ODD)
[partitioning("fractional_odd")]
#elif defined(_PARTITIONING_POW2)
[partitioning("pow2")]
#else
[partitioning("fractional_odd")]
#endif
TessellationControlPoint Hull(
    InputPatch<TessellationControlPoint, 3> patch, // Input triangle
    uint id : SV_OutputControlPointID) { // Vertex index on the triangle

    return patch[id];
}

// Call this macro to interpolate between a triangle patch, passing the field name
#define BARYCENTRIC_INTERPOLATE(fieldName) \
		patch[0].fieldName * barycentricCoordinates.x + \
		patch[1].fieldName * barycentricCoordinates.y + \
		patch[2].fieldName * barycentricCoordinates.z

// The domain function runs once per vertex in the final, tessellated mesh
// Use it to reposition vertices and prepare for the fragment stage
[domain("tri")] // Signal we're inputting triangles
Interpolators Domain(
    TessellationFactors factors, // The output of the patch constant function
    OutputPatch<TessellationControlPoint, 3> patch, // The Input triangle
    float3 barycentricCoordinates : SV_DomainLocation) { // The barycentric coordinates of the vertex on the triangle

    Interpolators output;

    // Setup instancing and stereo support (for VR)
    UNITY_SETUP_INSTANCE_ID(patch[0]);
    UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    float3 positionWS = BARYCENTRIC_INTERPOLATE(positionWS);

    output.positionCS = TransformWorldToHClip(positionWS);
    output.normalWS = (patch[0].normalWS + patch[1].normalWS + patch[2].normalWS) / 3.0;
    output.tangentWS = (patch[0].tangentWS + patch[1].tangentWS + patch[2].tangentWS) / 3.0;
    output.positionWS = positionWS;

    output.uv = float2(0, 0);
    output.color = BARYCENTRIC_INTERPOLATE(color);

    return output;
}

// struct Interpolators {
//     float3 normalWS                 : TEXCOORD0;
//     float3 positionWS               : TEXCOORD1;
//     float4 positionCS               : SV_POSITION;
//     UNITY_VERTEX_INPUT_INSTANCE_ID
//     UNITY_VERTEX_OUTPUT_STEREO
// };

float _DisCutoff;

[maxvertexcount(6)]
void Geometry(triangle Interpolators input[3], inout TriangleStream<Interpolators> outStream) {

  if (input[0].color.g < 0.1f && input[0].color.r > 0.9f)
    return;

  float3 basePos = (input[0].positionWS.xyz + input[1].positionWS.xyz + input[2].positionWS.xyz) / 3;

  float dis = mag(TransformWorldToHClip(basePos));
  if (dis > _DisCutoff) { return; }

  Interpolators o1 = input[0];
  Interpolators o2 = input[0];
  Interpolators o3 = input[0];
  Interpolators o4 = input[0];

  float3 temp = _WorldSpaceCameraPos.xyz - basePos.xyz;
  float diff = dot(o1.normalWS, temp) / (mag(o1.normalWS) * mag(temp));
  float flag1 = max(0, diff - 0.14);
  float flag2 = min(0, diff - 0.94);

  float3 rotatedTangent = cross(o1.normalWS, WorldSpaceViewDir(basePos)).xyz;// * flag2, o1.tangentWS.xyz);//normalize(o1.tangentWS);//normalize(mul(o1.tangentWS, RotY(rand(o1.positionWS.xyz) * 90)));
  rotatedTangent = mul(rotatedTangent, RotY((rand(o1.positionWS.xyz) - 0.5) * (PI / 0.25)));
  rotatedTangent = normalize(rotatedTangent);

  float3 o1Pos = (basePos - rotatedTangent * _Base);
  float3 o2Pos = (basePos + rotatedTangent * _Base);
  float3 o3Pos = (basePos + rotatedTangent * _Base + o1.normalWS * _Height);
  float3 o4Pos = (basePos - rotatedTangent * _Base + o1.normalWS * _Height);

  o1.positionCS = TransformWorldToHClip(o1Pos);
  o2.positionCS = TransformWorldToHClip(o2Pos);
  o3.positionCS = TransformWorldToHClip(o3Pos);
  o4.positionCS = TransformWorldToHClip(o4Pos);

  float3 newNormal = mul(rotatedTangent, RotY(PI / 2));

  o1.normalWS = newNormal;
  o2.normalWS = newNormal;
  o3.normalWS = newNormal;
  o4.normalWS = newNormal;

  o1.positionWS = o1Pos;
  o2.positionWS = o2Pos;
  o3.positionWS = o3Pos;
  o4.positionWS = o4Pos;

  o1.tangentWS = rotatedTangent;
  o2.tangentWS = rotatedTangent;
  o3.tangentWS = rotatedTangent;
  o4.tangentWS = rotatedTangent;

  o4.uv = TRANSFORM_TEX(float2(0, 1), _BaseMap);
  o3.uv = TRANSFORM_TEX(float2(1, 1), _BaseMap);
  o2.uv = TRANSFORM_TEX(float2(1, 0), _BaseMap);
  o1.uv = TRANSFORM_TEX(float2(0, 0), _BaseMap);

  outStream.Append(o4);
  outStream.Append(o3);
  outStream.Append(o1);

  outStream.RestartStrip();

  outStream.Append(o3);
  outStream.Append(o2);
  outStream.Append(o1);

  outStream.RestartStrip();

}

float4 _Tint;
float4 _Darker;
float _LightPower;
float _TPower;
float _ShadowPower;
float _AlphaCutoff;

float4 Fragment(Interpolators input, bool vf : SV_IsFrontFace) : SV_Target {
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    float3 normalWS = normalize(input.normalWS);
    if (vf == true) { normalWS = -normalWS; }


    half3 color = (0, 0, 0);

    Light mainLight;
    mainLight = GetMainLight(TransformWorldToShadowCoord(input.positionWS.xyz));

    float3 normalLight = LightingLambert(mainLight.color, mainLight.direction, normalWS) * _LightPower;
    float3 inverseNormalLight = LightingLambert(mainLight.color, mainLight.direction, -normalWS) * _TPower;

    color = _Tint + normalLight + inverseNormalLight;
    color = lerp(color, _Darker, 1 - input.uv.y);
    color = lerp(_Darker, color, clamp(mainLight.shadowAttenuation + _ShadowPower, 0, 1));

    float a = _BaseMap.Sample(sampler_BaseMap, input.uv).a;
    clip(a - _AlphaCutoff);

    return half4(color, 1);
}

#endif
