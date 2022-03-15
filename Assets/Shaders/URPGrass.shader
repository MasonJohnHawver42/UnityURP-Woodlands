Shader "Unlit/URPGrass"
{
    Properties
    {
        [MainTexture] _BaseMap("Grass Texture",2D) = "white" {}
        _Height("Height", Float) = 1.0

        _WindDistortionMap ("Wind Distortion Map", 2D) = "white" {}
        _WindFrequency("Wind Frequency", Vector) = (0.05,0.05,0,0)
        _WindStrength("Wind Strength", Float) = 1
        _MinHeight("Minimum Height", Float) = 0
        _MaxHeight("Maximum Height", Float) = 1

        _Base("Base", Float) = 1.0
        _Tint("Tint", Color) = (0.5, 0.5, 0.5, 1)
        _Darker("Darker Color", Color) = (0.5, 0.5, 0.5, 1)
        _LightPower("Light Power", Float) = 0.05
        _TPower("Translucency Power", Float) = 0.02
        _ShadowPower("Shadow Power", Float) = 0.35
        _AlphaCutoff("Alpha Cutoff", Float) = 0.1

        _DetailPos("Detail Position", Vector) = (0, 0, 0)
        _DisCutoff("Distance Cutoff", Float) = 10.0

    }
        SubShader
        {
            Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
            LOD 100

            Pass
            {
                Name "Grass Pass"
                Tags {"LightMode"="UniversalForward"}

                ZWrite On
                Cull Off

                HLSLPROGRAM

                #pragma prefer_hlslcc gles
                #pragma exclude_renderers d3d11_9x
                #pragma target 5.0

                #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
                #pragma shader_feature _GLOSSYREFLECTIONS_OFF
                #pragma shader_feature _ALPHATEST_ON
                #pragma shader_feature _ALPHAPREMULTIPLY_ON
                #pragma shader_feature _SPECULAR_SETUP
                #pragma shader_feature _RECEIVE_SHADOWS_ON
                //#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

                #pragma multi_compile _ _SHADOWS_SOFT
                #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

                #pragma multi_compile _ DIRLIGHTMAP_COMBINED
                #pragma multi_compile _ LIGHTMAP_ON
                #pragma multi_compile_fog

                //#pragma require geometry


                #pragma geometry Geometry
                #pragma vertex Vertex
                #pragma fragment Fragment
                // #pragma hull Hull
                // #pragma domain Domain

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

                #include "GrassPass.hlsl"

                ENDHLSL

            }


    }
}
