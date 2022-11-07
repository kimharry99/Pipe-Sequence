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
fragment FragmentOut capturedImageFragmentShader(ImageColorInOut in [[stage_in]],
                                                 texture2d<float, access::sample> capturedImageTextureY [[ texture(kTextureIndexY) ]],
                                                 texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(kTextureIndexCbCr) ]],
                                                 depth2d<float, access::sample> depthMapTexture [[texture(kTextureIndexDepth)]]) {
    FragmentOut out;
    
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
    out.rgbColor = float4(1.0, (ycbcrToRGBTransform * ycbcr).rgb);
    
    // Set re-ranged depth value
    float depth = clamp(depthMapTexture.sample(s, in.texCoord), 0.0f, 5.0f) ;

    // Re-scale depth value
    out.depth = ((uint16_t) (depth * 13107.0f));
    return out;
}
