// 
// original file: primitive3D_corona_dir.fx
// original version: v1.5
// original author: Ren712
//
// modified by: rifleh700
//

//--------------------------------------------------------------------------------------
// Settings
//--------------------------------------------------------------------------------------
float3 sCoronaPosition = float3(0, 0, 0);
float3 sCoronaDirection = float3(0, 0, 1);

float sLightPhi = 0.6; // Phi is the outer cone angle
float sLightTheta = 0.3; // Theta is the inner cone angle
float sLightFalloff = 1.0; // light intensity attenuation between the phi and theta areas

float sCoronaScaleSpread = 0.85;

float fDepthBias = 1;
float2 gDistFade = float2(250, 150);

int fCullMode = 2;

//--------------------------------------------------------------------------------------
// Textures
//--------------------------------------------------------------------------------------
texture sCoronaTexture;

//--------------------------------------------------------------------------------------
// Variables set by MTA
//--------------------------------------------------------------------------------------
float4x4 gProjection : PROJECTION;
float4x4 gView : VIEW;
float4x4 gViewInverse : VIEWINVERSE;
float3 gCameraPosition : CAMERAPOSITION;
static const float PI = 3.14159265f;
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
	
	// set proper position
	VS.Position.xyz = VS.Position.xzy - sCoronaPosition.xzy;

	// create WorldMatrix for the quad
	float4x4 sWorld = createWorldMatrix(sCoronaPosition, float3(0,0,0));
	
	// get forward vector
	float3 fwVec = normalize(sCoronaDirection);
	
	// get distance from front plane
	float planeZDist = dot(fwVec, gCameraPosition - sCoronaPosition);
	
	// angle between front plane and view
	float angleZ = acos(dot(normalize(sCoronaPosition - gCameraPosition), fwVec));
	
	// deal with front/back case	
	angleZ = planeZDist > 0 ? (PI - angleZ) : PI / 2;
	
	float impactZ = pow(smoothstep(sLightPhi, sLightTheta, angleZ), sLightFalloff);
	if (angleZ > sLightPhi) impactZ = 0;
	
	// scale the quad based on impactZ
	float quadScale = (1 - sCoronaScaleSpread) + impactZ * sCoronaScaleSpread;
	VS.Position.xy *= quadScale;
	
	// calculate screen position of the vertex
	float4x4 sWorldView = mul(sWorld, gView);
	float3 vPos = VS.Position.xyz + sWorldView[3].xyz;	
	vPos.xyz += fDepthBias * 1.5 * mul(normalize(gCameraPosition - sCoronaPosition), (float3x3)gView).xyz;
	PS.Position = mul(float4(vPos, 1), gProjection);
	
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
	PS.Diffuse.a *= quadScale;
	
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
technique dxDrawPrimitive3D_corona_dir
{
	pass P0
	{
		ZEnable = true;
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
	