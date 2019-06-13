Shader "Custom/Distort" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		[NoScaleOffset] _FlowMap("Flow (RG)", 2D) = "black" {}
		_UJump("U jump per phase", Range(-0.25, 0.25)) = 0.25
		_VJump("V jump per phase", Range(-0.25, 0.25)) = 0.25
		_Tiling("Tiling", Float) = 1
		_Speed("Speed", Float) = 1
		_FlowStrength("Flow Strength", Float) = 1
		_FlowOffset("Flow Offset", Float) = 0
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
	}

	SubShader{
			Tags { "RenderType" = "Opaque" }
			LOD 200

			CGPROGRAM
			#pragma surface surf Standard fullforwardshadows
			#pragma target 3.0

			sampler2D _MainTex, _FlowMap;
			float _UJump, _VJump;
			float _Tiling, _Speed, _FlowStrength, _FlowOffset;

			struct Input {
				float2 uv_MainTex;
			};

			half _Glossiness;
			half _Metallic;
			fixed4 _Color;

			void surf(Input IN, inout SurfaceOutputStandard o) {
				float2 flowVector = (tex2D(_FlowMap, IN.uv_MainTex).rg * 2 - 1) * _FlowStrength;
				float noise = tex2D(_FlowMap, IN.uv_MainTex).a;
				float time = _Time.y * _Speed + noise;
				float2 jump = float2(_UJump, _VJump);

				//uvw flow for A, B:
				float phaseOffsetA = false ? 0.5 : 0; //uvwA
				float phaseOffsetB = true ? 0.5 : 0; //uvwA
				float progressA = frac(time + phaseOffsetA);
				float progressB = frac(time + phaseOffsetB);
				float3 uvwA, uvwB;
				//uvwA.xy = IN.uv_MainTex - flowVector * progressA + phaseOffsetA;
				uvwA.xy = IN.uv_MainTex - flowVector * (progressA + _FlowOffset);
				uvwA.xy *= _Tiling;
				uvwA.xy += phaseOffsetA;
				uvwA.xy += (time - progressA) * jump;
				uvwA.z = 1 - abs(1 - 2 * progressA);
				//uvwB.xy = IN.uv_MainTex - flowVector * progressB + phaseOffsetB;
				uvwB.xy = IN.uv_MainTex - flowVector * (progressB + _FlowOffset);
				uvwB.xy *= _Tiling;
				uvwB.xy += phaseOffsetB;
				uvwB.xy += (time - progressB) * jump;
				uvwB.z = 1 - abs(1 - 2 * progressB);
				
				//float2 uv = IN.uv_MainTex - flowVector * progress;
				fixed4 sampleA = tex2D(_MainTex, uvwA.xy) * uvwA.z;
				fixed4 sampleB = tex2D(_MainTex, uvwB.xy) * uvwB.z;
				fixed4 c = (sampleA + sampleB) * _Color;

				//outputs
				o.Albedo = c.rgb;
				o.Metallic = _Metallic;
				o.Smoothness = _Glossiness;
				o.Alpha = c.a;
			}
			ENDCG
		}
		Fallback "Diffuse"
}