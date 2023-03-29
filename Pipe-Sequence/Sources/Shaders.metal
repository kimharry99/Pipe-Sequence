//
//  Shaders.metal
//  Pipe-Sequence
//
//  Created by Dong-Min KIM on 2022/10/04.
//

#include <metal_stdlib>

// Include header shared between this Metal shader code and C code executing Metal API commands
#import "ShaderTypes.h"

using namespace metal;

typedef struct {
    float2 position [[attribute(kVertexAttributePosition)]];
    float2 texCoord [[attribute(kVertexAttributeTexcoord)]];
} ImageVertex;

typedef struct {
    float4 position [[position]];
    float2 texCoord;
} ImageColorInOut;

typedef struct {
    float4 rgbColor [[color(0)]];
    uint16_t depth [[color(1)]];
} FragmentOut;

// Captured image vertex function
vertex ImageColorInOut capturedImageVertexTransform(ImageVertex in [[stage_in]]) {
    ImageColorInOut out;
    
    // Pass through the image vertex's position
    out.position = float4(in.position, 0.0, 1.0);
    
    // Pass through the texture coordinate
    out.texCoord = in.texCoord;
    
    return out;
}

// Captured image fragment function
fragment float4 capturedImageFragmentShader(ImageColorInOut in [[stage_in]],
                                                 texture2d<float, access::sample> capturedImageTextureY [[ texture(kTextureIndexY) ]],
                                                 texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(kTextureIndexCbCr) ]]) {
    float4 out;
    
    constexpr sampler s(address::clamp_to_edge, filter::linear);

    const float4x4 ycbcrToRGBTransform = float4x4(
        float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
        float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
        float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
        float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
    );

    // Sample Y and CbCr textures to get the YCbCr color at the given texture coordinate
    float4 ycbcr = float4(capturedImageTextureY.sample(s, in.texCoord).r,
                          capturedImageTextureCbCr.sample(s, in.texCoord).rg, 1.0);

    // Set converted ARGB color
//    out.rgbColor = float4(1.0, (ycbcrToRGBTransform * ycbcr).rgb);
    out = float4(1.0, (ycbcrToRGBTransform * ycbcr).rgb);
    
    // Set re-ranged depth value
//    float depth = clamp(depthMapTexture.sample(s, in.texCoord), 0.0f, 5.0f) ;
//
//    // Re-scale depth value
//    out.depth = ((uint16_t) (depth * 13107.0f));
    return out;
}

fragment float4 renderTextureFragmentShader(ImageColorInOut in [[stage_in]],
                                            texture2d<float, access::sample> capturedImageTextureARGB [[texture(kTextureIndexColor)]]) {

    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);
    
    float4 argb = capturedImageTextureARGB.sample(colorSampler, in.texCoord);

    return float4(argb.yzw, argb.x);
}

fragment uint16_t filterDepthFragmentShader(ImageColorInOut in [[stage_in]],
depth2d<float, access::sample> rawDepthTexture [[texture(kTextureIndexRawDepth)]],
texture2d<uint> arDepthConfidence [[ texture(kTextureIndexConfidence) ]])
{
    const uint minConfidence = 0;

    // Create an object to sample textures.
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    
    float depth = rawDepthTexture.sample(s, in.texCoord);
    
    uint confidence = arDepthConfidence.sample(s, in.texCoord).x;
    if (confidence < minConfidence) {
        depth = 0.0f;
    }
    
    uint16_t outDepth = ((uint16_t) (depth * 13107.0f));
    
    return outDepth;
}
