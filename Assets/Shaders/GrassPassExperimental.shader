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

// This is a shader that demonstrates tessellation factors and partitioning modes

Shader "Mason/GrassPassExperimental" {
      Properties{

        [MainTexture] _BaseMap("Grass Texture",2D) = "white" {}

        _Height ("Height", Float) = 1.0
        _Base ("Base", Float) = 1.0

        _WindDistortionMap ("Wind Distortion Map", 2D) = "white" {}


        _Tint("Tint", Color) = (0.5, 0.5, 0.5, 1)
        _Darker("Darker Color", Color) = (0.5, 0.5, 0.5, 1)
        _LightPower("Light Power", Float) = 0.05
        _TPower("Translucency Power", Float) = 0.02
        _ShadowPower("Shadow Power", Float) = 0.35
        _AlphaCutoff("Alpha Cutoff", Float) = 0.1

        _DisCutoff("Distance Cutoff", Float) = 10.0

        _FactorEdge1("Edge factors", Vector) = (1, 1, 1, 0)
        _FactorEdge2("Edge 2 factor", Float) = 1
        _FactorEdge3("Edge 3 factor", Float) = 1
        _FactorInside("Inside factor", Float) = 1
        // This keyword enum allows us to choose between partitioning modes. It's best to try them out for yourself
        [KeywordEnum(INTEGER, FRAC_EVEN, FRAC_ODD, POW2)] _PARTITIONING("Partition algoritm", Float) = 0
    }
    SubShader{
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}

        Pass {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            ZWrite On
            Cull Off

            HLSLPROGRAM
            #pragma target 5.0 // 5.0 required for tessellation

            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _GLOSSYREFLECTIONS_OFF
            #pragma shader_feature _SPECULAR_SETUP
            #pragma shader_feature _RECEIVE_SHADOWS_ON
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            // Material keywords
            #pragma shader_feature_local _PARTITIONING_INTEGER _PARTITIONING_FRAC_EVEN _PARTITIONING_FRAC_ODD _PARTITIONING_POW2

            #pragma vertex Vertex
            #pragma hull Hull
            #pragma domain Domain
            #pragma geometry Geometry
            #pragma fragment Fragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            #include "GrassPassExperimental.hlsl"
            ENDHLSL
        }
    }
}
