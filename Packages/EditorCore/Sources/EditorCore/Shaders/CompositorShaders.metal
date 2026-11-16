#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
    float2 canvasPixelCoord;
};

struct Uniforms {
    float4x4 projectionMatrix;
    float4x4 modelViewMatrix;
    float2 canvasSize;
    float zoom;
    float opacity;
    int blendMode;
    int showPixelGrid;
};

vertex VertexOut compositor_vertex(
    const device VertexIn* vertices [[buffer(0)]],
    constant Uniforms& uniforms [[buffer(1)]],
    uint vid [[vertex_id]]
) {
    VertexOut out;
    float4 pos = float4(vertices[vid].position, 0.0, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * pos;
    out.texCoord = vertices[vid].texCoord;
    out.canvasPixelCoord = vertices[vid].texCoord * uniforms.canvasSize;
    return out;
}

// Background Checkerboard for Canvas Transparency
fragment float4 checkerboard_fragment(
    VertexOut in [[stage_in]],
    constant Uniforms& uniforms [[buffer(0)]]
) {
    float2 p = floor(in.canvasPixelCoord / 16.0);
    float pattern = fmod(p.x + p.y, 2.0);
    float3 col = (pattern == 0.0) ? float3(0.85, 0.85, 0.85) : float3(1.0, 1.0, 1.0);
    
    // Pixel grid at >= 800% zoom
    if (uniforms.showPixelGrid > 0) {
        float2 gridDist = abs(fract(in.canvasPixelCoord) - 0.5);
        if (gridDist.x > 0.48 || gridDist.y > 0.48) {
            col = mix(col, float3(0.6, 0.6, 0.6), 0.5);
        }
    }
    
    return float4(col, 1.0);
}

// Tile Blit & Blend Fragment
fragment float4 tile_blit_fragment(
    VertexOut in [[stage_in]],
    texture2d<float> layerTexture [[texture(0)]],
    sampler textureSampler [[sampler(0)]],
    constant Uniforms& uniforms [[buffer(0)]]
) {
    float4 src = layerTexture.sample(textureSampler, in.texCoord);
    src.a *= uniforms.opacity;
    
    // Pixel grid overlay on canvas pixels at extreme zoom
    if (uniforms.showPixelGrid > 0) {
        float2 gridDist = abs(fract(in.canvasPixelCoord) - 0.5);
        if (gridDist.x > 0.48 || gridDist.y > 0.48) {
            src.rgb = mix(src.rgb, float3(0.5, 0.5, 0.5), 0.3);
        }
    }
    
    return src;
}
