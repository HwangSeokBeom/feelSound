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
                               constant float3* touchInputs [[buffer(2)]],
                               constant int& maxTouches [[buffer(3)]],
                               constant float& u_time [[buffer(1)]],
                               texture2d<float> texture [[texture(0)]],
                               sampler s [[sampler(0)]]) {
    float2 uv = in.uv;
    float2 screenPos = in.screenPos;

    float2 offset = float2(0.0);
    for (int i = 0; i < maxTouches; ++i) {
        float2 pos = touchInputs[i].xy;
        float force = touchInputs[i].z;

        // slime_fragment 예시 (이미 있으나 더 강화 가능)
        float dist = distance(screenPos, pos);
        float ripple = sin(dist * 40.0 - u_time * 6.0) * 0.02 / (dist * 40.0 + 1.0);
        offset += ripple * float2(1.0, 0.6); // ✨ 수직/수평 비율 조절로 더 젤리 느낌

        offset.x += ripple;
        offset.y += ripple * 0.6;
    }

    return texture.sample(s, uv + offset);
}
