//
// original file: primitive3D_corona.fx
// original version: v1.5
// original author: Ren712
//
// modified by: rifleh700
//

//--------------------------------------------------------------------------------------
// Settings
//--------------------------------------------------------------------------------------
float3 sCoronaPosition = float3(0, 0, 0);

float fDepthBias = 1;
float2 gDistFade = float2(250, 150);
int fCullMode = 1;

//--------------------------------------------------------------------------------------
// Textures
//--------------------------------------------------------------------------------------
texture sCoronaTexture;

//--------------------------------------------------------------------------------------
// Variables set by MTA
//--------------------------------------------------------------------------------------
float4x4 gWorldViewProjection : WORLDVIEWPROJECTION;
float4x4 gProjection : PROJECTION;
float4x4 gView : VIEW;
float4x4 gViewInverse : VIEWINVERSE;
float3 gCameraPosition : CAMERAPOSITION;
float4 gFogColor < string renderState="FOGCOLOR"; >;
int CUSTOMFLAGS < string skipUnusedParameters = "yes"; >;

//--------------------------------------------------------------------------------------
// Sampler 
//--------------------------------------------------------------------------------------
sampler2D SamplerColor = sampler_state
{
	Texture = (sCoronaTexture);
	AddressU = Mirror;
	AddressV = Mirror;
};

//--------------------------------------------------------------------------------------
// Structures
//--------------------------------------------------------------------------------------
struct VSInput
{
	float3 Position : POSITION0;
	float2 TexCoord : TEXCOORD0;
	float4 Diffuse : COLOR0;
};

struct PSInput
{
	float4 Position : POSITION0;
	float2 TexCoord : TEXCOORD0;
	float DistFactor : TEXCOORD1;
	float DistFade : TEXCOORD2;
	float4 Diffuse : COLOR0;
};

//--------------------------------------------------------------------------------------
// Create world matrix with world position and euler rotation
//--------------------------------------------------------------------------------------
float4x4 createWorldMatrix(float3 pos, float3 rot)
{
	float4x4 eleMatrix = {
		float4(cos(rot.z) * cos(rot.y) - sin(rot.z) * sin(rot.x) * sin(rot.y), 
				cos(rot.y) * sin(rot.z) + cos(rot.z) * sin(rot.x) * sin(rot.y), -cos(rot.x) * sin(rot.y), 0),
		float4(-cos(rot.x) * sin(rot.z), cos(rot.z) * cos(rot.x), sin(rot.x), 0),
		float4(cos(rot.z) * sin(rot.y) + cos(rot.y) * sin(rot.z) * sin(rot.x), sin(rot.z) * sin(rot.y) - 
				cos(rot.z) * cos(rot.y) * sin(rot.x), cos(rot.x) * cos(rot.y), 0),
		float4(pos.x,pos.y,pos.z, 1),
	};
	return eleMatrix;
}

//--------------------------------------------------------------------------------------
// Vertex Shader 
//--------------------------------------------------------------------------------------
PSInput VertexShaderFunction(VSInput VS)
{
	PSInput PS = (PSInput)0;
	
	// create WorldMatrix for the quad
	float4x4 sWorld = createWorldMatrix(sCoronaPosition, float3(0,0,0));

	// calculate screen position of the vertex
	float4x4 sWorldView = mul(sWorld, gView);
	float3 sBillView = VS.Position.xzy - sCoronaPosition.xzy + sWorldView[3].xyz;
	sBillView.xyz += fDepthBias * 1.5 * mul(normalize(gCameraPosition - sCoronaPosition), (float3x3)gView).xyz;
	PS.Position = mul(float4(sBillView, 1), gProjection);
	
	// get clip values
	float nearClip = - gProjection[3][2] / gProjection[2][2];
	float farClip = (gProjection[3][2] / (1 - gProjection[2][2]));	
	
	// fade corona
	float DistFromCam = distance(gCameraPosition, sCoronaPosition.xyz);
	float2 DistFade = float2(min(gDistFade.x, farClip - 0.5), min(gDistFade.y, farClip - 0.5 - (gDistFade.x - gDistFade.y)));
	PS.DistFade = saturate((DistFromCam - DistFade.x)/(DistFade.y - DistFade.x));
	
	DistFromCam /= fDepthBias;
	PS.DistFactor = saturate(DistFromCam * 0.5 - 1.6);	

	// pass texCoords and vertex color to PS
	PS.TexCoord = VS.TexCoord;
	PS.Diffuse = VS.Diffuse;
	
	return PS;
}

//--------------------------------------------------------------------------------------
// Pixel shaders 
//--------------------------------------------------------------------------------------
float4 PixelShaderFunction(PSInput PS) : COLOR0
{
	// sample color texture
	float4 finalColor = tex2D(SamplerColor, PS.TexCoord.xy);
	
	// Set for corona
	finalColor.rgb = pow(finalColor.rgb * 1.2, 1.5);
	finalColor *= PS.Diffuse;
	finalColor.a *= PS.DistFactor;
	finalColor.a *= saturate(PS.DistFade);

	return saturate(finalColor);
}

//--------------------------------------------------------------------------------------
// Techniques
//--------------------------------------------------------------------------------------
technique dxDrawPrimitive3Dfx_corona
{
	pass P0
	{
		ZEnable = true;
		ZFunc = LessEqual;
		ZWriteEnable = false;
		CullMode = fCullMode;
		ShadeMode = Gouraud;
		AlphaBlendEnable = true;
		SrcBlend = SrcAlpha;
		DestBlend = One;
		AlphaTestEnable = true;
		AlphaRef = 1;
		AlphaFunc = GreaterEqual;
		Lighting = false;
		FogEnable = false;
		VertexShader = compile vs_2_0 VertexShaderFunction();
		PixelShader  = compile ps_2_0 PixelShaderFunction();
	}
}

// Fallback
technique fallback
{
	pass P0
	{
		// Just draw normally
	}
}
	