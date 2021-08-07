        uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
        uniform sampler2D _SSSTex; uniform float4 _SSSTex_ST;
        uniform sampler2D _ILMTex; uniform float4 _ILMTex_ST;

        uniform float _SpecIntensity;
        uniform float _DarkenInnerLineColor;
        struct VertexInput {
            float4 vertex : POSITION;
            float4 color :COLOR;
            float3 normal : NORMAL;
            float4 tangent : TANGENT;
            float2 texcoord0 : TEXCOORD0;
        };

        struct VertexOutput {
            float4 pos : SV_POSITION;
            float4 color :COLOR;
            float2 uv0 : TEXCOORD0;
            float4 posWorld : TEXCOORD1;
            float3 normalDir : TEXCOORD2;
            //float3 tangentDir : TEXCOORD3;
            //float3 bitangentDir : TEXCOORD4;
            LIGHTING_COORDS(6,7)
            UNITY_FOG_COORDS(8)
        };

        VertexOutput vert (VertexInput v) {
            VertexOutput o = (VertexOutput)0;
            o.uv0 = v.texcoord0;
            o.normalDir = UnityObjectToWorldNormal(v.normal);
            //o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
            //o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
            o.posWorld = mul(unity_ObjectToWorld, v.vertex);
            o.pos = UnityObjectToClipPos( v.vertex );
            o.color = v.color;
            UNITY_TRANSFER_FOG(o,o.pos);
            TRANSFER_VERTEX_TO_FRAGMENT(o)
            return o;
        }

        float4 frag(VertexOutput i, fixed facing : VFACE) : SV_TARGET {
            float2 Set_UV0 = i.uv0;
            fixed4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(Set_UV0, _MainTex));
            fixed4 _SSSTex_var = tex2D(_SSSTex, TRANSFORM_TEX(Set_UV0, _SSSTex));
            fixed4 _ILMTex_var = tex2D(_ILMTex, TRANSFORM_TEX(Set_UV0, _ILMTex));
            half4 finalcolor = half4(0, 0, 0, 1);
            half3 BrightColor = _MainTex_var.rgb;
            half3 ShadowColor = _MainTex_var.rgb * _SSSTex_var.rgb;
            float clampedLineColor = _ILMTex_var.a;
            if (clampedLineColor < _DarkenInnerLineColor)
                clampedLineColor = _DarkenInnerLineColor;

            half3 InnerLineColor = half3(clampedLineColor, clampedLineColor, clampedLineColor);

            float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
            i.normalDir = normalize(i.normalDir);
            half NdotL = dot(lightDirection, i.normalDir);

            half specStrength = _ILMTex_var.r;

            float vertColor = i.color.r;
            half3 ShadowThreshold = _ILMTex_var.g * i.color.r;
            ShadowThreshold *= vertColor;
            ShadowThreshold = 1 - ShadowThreshold;

            half SpecularSize = 1 - _ILMTex_var.b; 


            NdotL -= ShadowThreshold;
 
            if (NdotL < 0)
            {
                
                if ( NdotL < - SpecularSize - 0.5f)
                {
                    finalcolor.rgb = ShadowColor * (1 + specStrength);
                }
                else
                {
                    finalcolor.rgb = ShadowColor;
                }
            }
            else
            {
                if ( NdotL * 1.8f > SpecularSize)
                {
                    finalcolor.rgb = BrightColor * (1 + specStrength) * _SpecIntensity;
                }
                else
                {
                    finalcolor.rgb = BrightColor;
                }

            }

            finalcolor.rgb *= InnerLineColor;
            return finalcolor;
        }