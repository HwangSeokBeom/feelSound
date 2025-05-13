//
//  File.metal
//  feelsound
//
//  Created by Hwangseokbeom on 5/13/25.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 uv [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
    float2 screenPos;
};

vertex VertexOut slime_vertex(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = float4(in.position, 0, 1);
    out.uv = in.uv;
    out.screenPos = in.position;
    return out;
}

fragment float4 slime_fragment(VertexOut in [[stage_in]],
                               constant float2& u_touch [[buffer(0)]],
                               constant float& u_time [[buffer(1)]],
                               texture2d<float> texture [[texture(0)]],
                               sampler s [[sampler(0)]]) {
    float2 uv = in.uv;

    float dist = distance(in.screenPos, u_touch);

    float strength = 0.02;
    float frequency = 40.0;
    float speed = 6.0;

    float ripple = sin(dist * frequency - u_time * speed) * strength / (dist * frequency + 1.0);
    uv.x += ripple;
    uv.y += ripple * 0.6;

    return texture.sample(s, uv);
}
