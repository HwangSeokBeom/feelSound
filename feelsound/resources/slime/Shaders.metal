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
        float ripple = 0.0;

        if (deform.shapeType == 0) {
            ripple = sin(dist * deform.waveFreq - u_time * deform.waveSpeed)
                   * deform.intensity / (dist * deform.waveFreq + 1.0);
        } else if (deform.shapeType == 1) {
            ripple = sin(dist * deform.waveFreq * 1.5 + cos(dist * 20.0 - u_time * 10.0))
                   * deform.intensity * 0.5;
        } else if (deform.shapeType == 2) {
            ripple = cos(dist * deform.waveFreq - u_time * deform.waveSpeed)
                   * exp(-dist * 8.0) * deform.intensity * 2.0;
        } else if (deform.shapeType == 3) {
            ripple = smoothstep(0.5, 0.0, dist) * deform.intensity;
        } else if (deform.shapeType == 4) {
            ripple = step(0.02, fract(dist * deform.waveFreq - u_time * deform.waveSpeed))
                   * deform.intensity * 0.7;
        }

        float2 rippleOffset = float2(1.0, 0.6);
        if (deform.shapeType == 1) rippleOffset = float2(0.8, 1.0);
        else if (deform.shapeType == 2) rippleOffset = float2(-1.0, 1.0);
        else if (deform.shapeType == 3) rippleOffset = float2(0.5, 0.3);
        else if (deform.shapeType == 4) rippleOffset = float2(1.5, -0.5);

        offset += ripple * rippleOffset;
    }

    // (2) 기본 애니메이션: 터치가 없을 때도 흔들림 효과 제공
    if (maxTouches == 0) {
        float ripple = 0.0;
        float2 rippleOffset = float2(0.0);
        float dist = length(screenPos);
        
        if (deform.shapeType == 0) {
            // fudge: 물결이 계속 흐르듯, 시간 따라 중심 이동
            ripple = sin(dist * 10.0 + u_time * 3.0) * deform.intensity * 1.5;
            rippleOffset = float2(sin(u_time * 0.9 + screenPos.y * 3.0), cos(u_time * 0.6 + screenPos.x * 3.0)) * 0.5;
        } else if (deform.shapeType == 1) {
            // glitter: 고속 진동 유지
            ripple = sin(dist * 40.0 + u_time * 8.0 + cos(dist * 10.0)) * deform.intensity * 0.5;
            rippleOffset = float2(0.4 * sin(u_time * 2.0), 0.4 * cos(u_time * 2.0));
        } else if (deform.shapeType == 2) {
            // bubble: 중심에서 밖으로 퍼지는 호흡처럼
            ripple = sin(dist * 12.0 - u_time * 5.0) * deform.intensity * 1.4;
            rippleOffset = normalize(screenPos) * (0.25 + 0.15 * sin(u_time * 2.0));
        } else if (deform.shapeType == 3) {
            // moss: 점성이 흐르는 방향성 + 웨이브 섞기
            ripple = sin(dist * 6.0 + u_time * 1.5) * deform.intensity * 1.7;
            rippleOffset = float2(0.4, 0.1) * sin(u_time + dist * 4.0);
        } else if (deform.shapeType == 4) {
            // metallic: 빠르게 반짝이며 흔들림 유지
            ripple = step(0.05, fract(dist * 15.0 + u_time * 3.0)) * deform.intensity * 0.8;
            rippleOffset = float2(cos(u_time * 2.0), sin(u_time * 3.0)) * 0.3;
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
