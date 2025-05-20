//
//  File.metal
//  feelsound
//
//  Created by Hwangseokbeom on 5/13/25.
//

#include <metal_stdlib>
using namespace metal;

// MARK: - 공통 구조체 정의
struct VertexIn {
    float2 position [[attribute(0)]];
    float2 uv [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
    float2 screenPos;
};

// MARK: - 슬라임 변형 파라미터
struct DeformationParams {
    float waveFreq;
    float waveSpeed;
    float intensity;
    int shapeType;
};

// MARK: - 버텍스 셰이더
vertex VertexOut slime_vertex(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = float4(in.position, 0, 1);
    out.uv = in.uv;
    out.screenPos = in.position;
    return out;
}

// MARK: - 프래그먼트 셰이더
fragment float4 slime_fragment(VertexOut in [[stage_in]],
                               constant float3* touchInputs [[buffer(2)]],
                               constant int& maxTouches [[buffer(3)]],
                               constant float& u_time [[buffer(1)]],
                               constant DeformationParams& deform [[buffer(4)]],
                               texture2d<float> texture [[texture(0)]],
                               sampler s [[sampler(0)]]) {
    float2 uv = in.uv;
    float2 screenPos = in.screenPos;

    float2 offset = float2(0.0);

    // (1) 터치 기반 변형
    for (int i = 0; i < maxTouches; ++i) {
        float2 pos = touchInputs[i].xy;
        float force = touchInputs[i].z;
        float dist = distance(screenPos, pos);
        float2 pressOffset = float2(0.0);

        if (deform.shapeType == 5) {
            float falloff = exp(-pow(dist * 6.0, 2.0));
            float intensity = -0.04 * force * deform.intensity;
            pressOffset = normalize(screenPos - pos) * intensity * falloff;
        } else if (deform.shapeType == 4) {
            float ripple = sin(dist * 20.0 - u_time * 8.0) * deform.intensity * 0.6 * force;
            float angle = fract(sin(dot(screenPos + pos, float2(12.9898, 78.233))) * 43758.5453) * 6.2831;
            float2 rippleOffset = float2(cos(angle), sin(angle)) * 0.3;
            pressOffset = ripple * rippleOffset;
        } else {
            float ripple = 0.0;
            float2 rippleOffset = float2(1.0, 0.6);

            if (deform.shapeType == 0) {
                ripple = sin(dist * 8.0 - u_time * 2.0) * exp(-dist * 3.0) * force * deform.intensity;
                rippleOffset = normalize(screenPos - pos);
            } else if (deform.shapeType == 1) {
                ripple = sin(dist * 40.0 - u_time * 8.0 + fract(screenPos.x * 13.37)) * deform.intensity * 0.5 * force;
                rippleOffset = float2(cos(u_time * 10.0), sin(u_time * 12.0));
            } else if (deform.shapeType == 2) {
                ripple = smoothstep(0.3, 0.0, dist - sin(u_time * 3.0)) * deform.intensity * 2.0 * force;
                rippleOffset = normalize(pos - screenPos);
            } else if (deform.shapeType == 3) {
                ripple = (1.0 - dist) * sin(u_time + screenPos.x * 3.0) * deform.intensity * 1.2 * force;
                rippleOffset = float2(0.4, 0.2);
            }

            pressOffset = ripple * rippleOffset;
        }

        offset += pressOffset;
    }

    // (2) 기본 애니메이션 (터치 없을 때)
    if (maxTouches == 0) {
        float ripple = 0.0;
        float2 rippleOffset = float2(0.0);
        float dist = length(screenPos);

        if (deform.shapeType == 0) {
            ripple = sin(dist * 10.0 + u_time * 3.0) * deform.intensity * 1.5;
            rippleOffset = float2(sin(u_time * 0.9 + screenPos.y * 3.0), cos(u_time * 0.6 + screenPos.x * 3.0)) * 0.5;
        } else if (deform.shapeType == 1) {
            ripple = sin(dist * 40.0 + u_time * 8.0 + cos(dist * 10.0)) * deform.intensity * 0.5;
            rippleOffset = float2(0.4 * sin(u_time * 2.0), 0.4 * cos(u_time * 2.0));
        } else if (deform.shapeType == 2) {
            ripple = sin(dist * 12.0 - u_time * 5.0) * deform.intensity * 1.4;
            rippleOffset = normalize(screenPos) * (0.25 + 0.15 * sin(u_time * 2.0));
        } else if (deform.shapeType == 3) {
            ripple = sin(dist * 6.0 + u_time * 1.5) * deform.intensity * 1.7;
            rippleOffset = float2(0.4, 0.1) * sin(u_time + dist * 4.0);
        } else if (deform.shapeType == 4) {
            float ripple = sin(dist * 20.0 - u_time * 8.0) * deform.intensity * 0.6;
            float angle = fract(sin(dot(screenPos, float2(23.456, 87.654))) * 12345.6789) * 6.2831;
            rippleOffset = float2(cos(angle), sin(angle)) * 0.3;
        }

        offset += ripple * rippleOffset;
    }

    // 조명 효과
    float3 normal = normalize(float3(screenPos.x, screenPos.y,
                           sqrt(max(0.0, 1.0 - clamp(dot(screenPos, screenPos), 0.0, 1.0)))));
    float3 lightDir = normalize(float3(0.3, 0.4, 1.0));
    float fakeLighting = clamp(dot(normal, lightDir), 0.0, 1.0);

    float3 baseColor = texture.sample(s, uv + offset).rgb;
    float3 finalColor = baseColor * (0.9 + fakeLighting * 0.2);

    return float4(finalColor, 1.0);
}
