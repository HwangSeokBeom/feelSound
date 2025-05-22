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

struct DeformationParams {
    float waveFreq;
    float waveSpeed;
    float intensity;
    int shapeType;
};

vertex VertexOut slime_vertex(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = float4(in.position, 0, 1);
    out.uv = in.uv;
    out.screenPos = in.position;
    return out;
}

float3 calculateLighting(float2 screenPos, float2 displacement) {
    float3 normal = normalize(float3(-displacement.x * 8.0, -displacement.y * 8.0, 0.8));
    float3 lightDir = normalize(float3(0.3, 0.4, 1.0));
    float diffuse = max(dot(normal, lightDir), 0.0);
    float specular = pow(max(dot(reflect(-lightDir, normal), float3(0, 0, 1)), 0.0), 16.0) * 0.2;
    return float3(0.9 + diffuse * 0.3 + specular);
}

fragment float4 slime_fragment(VertexOut in [[stage_in]],
                               constant float3* touchInputs [[buffer(2)]],
                               constant int& maxTouches [[buffer(3)]],
                               constant float& u_time [[buffer(1)]],
                               constant DeformationParams& deform [[buffer(4)]],
                               texture2d<float> texture [[texture(0)]],
                               sampler s [[sampler(0)]]) {
    float2 uv = in.uv;
    float2 screenPos = in.screenPos;
    float2 displacement = float2(0.0);
    float pressure = 0.0;
    bool hasTouches = false;

    if (maxTouches > 0) {
        for (int i = 0; i < maxTouches; ++i) {
            float2 touchPos = touchInputs[i].xy;
            float force = touchInputs[i].z;
            if (touchPos.x < -5.0) continue;
            hasTouches = true;
            float dist = distance(screenPos, touchPos);
            float radius = 0.3;
            float falloff = exp(-pow(dist / radius * 3.0, 2.0));
            float2 direction = normalize(screenPos - touchPos);
            displacement += direction * falloff * force * deform.intensity * 0.03;
            pressure += falloff * force;
        }
    } else {
        float dist = length(screenPos);
        float angle = atan2(screenPos.y, screenPos.x);
        float breathe = sin(u_time * 0.5) * 0.1 + 0.9;
        float wave = 0.0;
        if (deform.shapeType == 0) {
            wave = sin(dist * 2.0 + u_time * 0.4) * sin(angle * 2.0 + u_time * 0.2);
        } else if (deform.shapeType == 1) {
            wave = sin(dist * 5.0 + u_time * 0.8) * cos(angle * 3.0 + u_time * 0.5);
        } else if (deform.shapeType == 2) {
            wave = sin(dist * 3.0 + u_time * 0.6) * cos(angle * 2.0 + u_time * 0.3);
        } else if (deform.shapeType == 3) {
            wave = sin(dist * 1.5 + u_time * 0.3) * sin(angle + u_time * 0.1);
        } else if (deform.shapeType == 4) {
            wave = sin(dist * 4.0 + u_time * 0.7) * cos(angle * 4.0 + u_time * 0.4);
        }
        displacement += normalize(screenPos) * wave * breathe * deform.intensity * 0.005;
    }

    float displacementStrength = length(displacement);
    float maxDisplacement = 0.05;
    if (displacementStrength > maxDisplacement) {
        displacement = normalize(displacement) * maxDisplacement;
    }

    float2 edgeFactor = float2(
        smoothstep(0.0, 0.2, uv.x) * smoothstep(0.0, 0.2, 1.0 - uv.x),
        smoothstep(0.0, 0.2, uv.y) * smoothstep(0.0, 0.2, 1.0 - uv.y)
    );
    displacement *= edgeFactor.x * edgeFactor.y;

    float2 finalUV = clamp(uv - displacement * 0.05, float2(0.01), float2(0.99));
    float3 baseColor = texture.sample(s, finalUV).rgb;
    float3 lighting = calculateLighting(screenPos, displacement);
    float3 typeEffect = float3(1.0);

    if (deform.shapeType == 1) {
        float glitter = fract(sin(dot(screenPos + float2(u_time * 0.2), float2(12.9898, 78.233))) * 43758.5453);
        float glitterMask = step(0.7, glitter) * pressure * 0.5;
        typeEffect += float3(glitterMask);
    } else if (deform.shapeType == 4) {
        typeEffect = mix(float3(0.9, 0.95, 1.0), float3(1.0, 1.05, 1.1), pressure * 0.3);
    }

    float3 finalColor = baseColor * lighting * typeEffect;
    float touchEnhance = smoothstep(0.0, 1.0, pressure * 2.0) * 0.15;
    finalColor = mix(finalColor, finalColor * (1.0 + touchEnhance), min(touchEnhance, 0.3));
    return float4(finalColor, 1.0);
}
