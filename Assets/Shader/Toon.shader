Shader "Ciel/Toon" {
    Properties{

        _MainTex("基础颜色 (RGB)", 2D) = "white" {}
        _SSSTex("暗部颜色 (RGB)", 2D) = "white" {}
        _ILMTex("光照控制 (RGBA)", 2D) = "white" {}
        _SpecIntensity("高光强度", Range(1,2)) = 1.5
        _DarkenInnerLineColor("内描边弱化", Range(0, 1)) = 0

        [Space(20)]
        _OutlineColor("外描边颜色", Color) = (0,0,0,1)
        _OutlineWidth("外描边宽度",Range(0,0.2)) = 0.004
        [Space(20)]
        _LightDir("阴影方向",Vector) = (1,1,1,-0.01)
        _ShadowColor("阴影颜色",Color) = (0,0,0,0.5)
        _ShadowFalloff("阴影衰减",Range(0,1)) = 0
    }

    SubShader 
    {
        Pass
        {
            Name "Outline"
            Tags{}
            Cull Front 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            sampler2D _MainTex;
            sampler2D _SSSTex;
            sampler2D _ILMTex;
            half4 _OutlineColor;
            half _OutlineWidth;

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 tex : TEXCOORD0;
            };
            
            v2f vert (appdata_full v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                float3 norm = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                float2 offset = TransformViewToProjection(norm.xy);
                o.pos.xy += offset * _OutlineWidth * v.color.a;
                o.tex = v.texcoord;
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 cLight = tex2D(_MainTex, i.tex.xy);
                fixed4 cSSS = tex2D(_SSSTex, i.tex.xy);
                fixed4 cDark = cLight * cSSS;
                cDark = cDark * _OutlineColor;
                cDark.a = 1; 
                return cDark;
            }
            ENDCG
        }

        Pass
        {
            Name "PlaneShadow"
            Stencil
            {
                Ref 0
                Comp equal
                Pass incrWrap
                Fail keep
                ZFail keep
            }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite off
            Offset -10 , 0

            CGPROGRAM
            #pragma shader_feature _INVISIBILITY_ON
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Role_ShadowCaster.cginc"
            ENDCG
        }

        Pass {
            Name "Cel"
            Tags {
                "LightMode"="ForwardBase"
            }        
            
            CGPROGRAM
            #pragma shader_feature _INVISIBILITY_ON
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma multi_compile_fog

            #pragma target 3.0
            
            #include "Role_Cel.cginc"
            ENDCG
        }
    }
    //FallBack "Diffuse"
}
