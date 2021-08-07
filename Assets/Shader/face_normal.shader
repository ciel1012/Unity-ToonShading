Shader "Ciel/Face Normal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ShadowColor("Shadow Color", Color) = (1,1,1,1)
        _NoramlTex("Normal",2D) = "bump" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color :COLOR;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 pos : SV_POSITION;
                float4 color :COLOR;
                float4 posWorld : TEXCOORD2;
                float3 normalDir : TEXCOORD3;
                float3 tangentDir : TEXCOORD4;
                float3 bitangentDir : TEXCOORD5;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _ShadowColor;
            sampler2D _NoramlTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);

                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.color = v.color;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 _MainTex_var = tex2D(_MainTex, i.uv);
                half3 BrightColor = _MainTex_var.rgb;
                half3 ShadowColor = _MainTex_var.rgb * _ShadowColor.rgb;
                half4 finalcolor = half4(0, 0, 0, 1);
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                i.normalDir = normalize(i.normalDir);
                
                float3x3 tangentTransform = float3x3(i.tangentDir,i.bitangentDir,i.normalDir);
                float3 _NoramlTex_var = UnpackNormal(tex2D(_NoramlTex,i.uv));
                float3 normalDirection = normalize(mul(_NoramlTex_var,tangentTransform)); //切线空间转世界空间
                //float3 normalDirection = normalize(UnityObjectToWorldNormal(_NoramlTex_var.xyz)); //模型空间转世界空间
                half NdotL = dot(lightDirection, normalDirection);

                if (NdotL < 0)
                {
                    finalcolor.rgb = ShadowColor;
                }
                else
                {
                    finalcolor.rgb = BrightColor;

                }
                //finalcolor.rgb = normalDirection;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return finalcolor;
            }
            ENDCG
        }
    }
}
