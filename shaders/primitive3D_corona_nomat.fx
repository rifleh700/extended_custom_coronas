//
// file: primitive3D_corona_nomat.fx
// version: v1.6
// author: Ren712
//

//--------------------------------------------------------------------------------------
// Settings
//--------------------------------------------------------------------------------------
float3 sElementPosition = float3(0,0,0);
float4 sElementColor = float4(0, 0, 0, 0);
float sElementSize = 1;
float sLightAttenuationPower = 2;

float fDepthBias = 1;
float2 gDistFade = float2(250,150);

int fCullMode = 2;

//--------------------------------------------------------------------------------------
// Variables set by MTA
//--------------------------------------------------------------------------------------
float4x4 gProjection : PROJECTION;
float4x4 gView : VIEW;
float4x4 gViewInverse : VIEWINVERSE;
float3 gCameraPosition : CAMERAPOSITION;
int CUSTOMFLAGS < string skipUnusedParameters = "yes"; >;

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
    float DistFade : TEXCOORD1;
    float DistFactor : TEXCOORD2;
    float3 WorldPos : TEXCOORD3;
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

    // set proper position and scale of the quad
    VS.Position.xyz = float3(- 0.5 + VS.TexCoord.xy, 0);

    VS.Position.xy *= sElementSize;

    // flip texCoords.x
    VS.TexCoord.x = 1 - VS.TexCoord.x;

    // create WorldMatrix for the quad
    float4x4 sWorld = createWorldMatrix(sElementPosition, float3(0,0,0));

    // calculate screen position of the vertex
    float4x4 sWorldView = mul(sWorld, gView);
    float3 vPos = VS.Position.xyz + sWorldView[3].xyz;
    PS.WorldPos = VS.Position.xyz + sWorld[3].xyz;
    vPos.xyz += fDepthBias * 1.5 * mul( normalize(gCameraPosition - sElementPosition), (float3x3)gView).xyz;
    PS.Position = mul(float4(vPos, 1), gProjection);

    // get clip values
    float nearClip = - gProjection[3][2] / gProjection[2][2];
    float farClip = (gProjection[3][2] / (1 - gProjection[2][2]));

    // fade object
    float DistFromCam = distance(gCameraPosition, sElementPosition);
    float2 DistFade = float2(min(gDistFade.x, farClip + sElementSize / 2), min(gDistFade.y, farClip + sElementSize /2 - (gDistFade.x - gDistFade.y)));
    PS.DistFade = saturate((DistFromCam - DistFade.x)/(DistFade.y - DistFade.x));

    DistFromCam /= fDepthBias;
    PS.DistFactor = saturate( DistFromCam * 0.5 - 1.6 );

    // pass texCoords and vertex color to PS
    PS.TexCoord = VS.TexCoord;
    PS.Diffuse = VS.Diffuse * sElementColor;

    return PS;
}

//--------------------------------------------------------------------------------------
// Pixel shaders
//--------------------------------------------------------------------------------------
float4 PixelShaderFunction(PSInput PS) : COLOR0
{
    // compute the distance attenuation factor
    float fDistance = distance(sElementPosition, PS.WorldPos);

    // compute the attenuation
    float fAttenuation = 1 - saturate(fDistance / (sElementSize*0.5));
    fAttenuation = pow(fAttenuation, sLightAttenuationPower);
	
    // apply diffuse color
    float4 finalColor = PS.Diffuse;
	
    // apply diffuse color
    finalColor.rgb *= saturate(fAttenuation);

    // set fade
    finalColor.rgb *= PS.DistFactor;
    finalColor.rgb *= saturate(PS.DistFade);
	
    return saturate(finalColor);
}

//--------------------------------------------------------------------------------------
// Techniques
//--------------------------------------------------------------------------------------
technique dxDrawPrimitive3Dfx_corona_nomat
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
