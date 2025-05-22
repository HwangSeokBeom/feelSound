//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/13/25.
//

import Foundation
import MetalKit
import AVFoundation

struct SlimeVertex {
    var position: SIMD2<Float>
    var uv: SIMD2<Float>
    var original: SIMD2<Float>
    var velocity: SIMD2<Float> = .zero
}

struct SlimeTouch {
    let id: ObjectIdentifier
    let position: SIMD2<Float>
    let force: Float
    var previousPosition: SIMD2<Float>?
}

struct DeformationParams {
    var waveFreq: Float
    var waveSpeed: Float
    var intensity: Float
    var shapeType: Int32
}

class SlimeRenderer: NSObject, MTKViewDelegate {
    private let config: SlimeConfig
    private let soundPlayer: SlimeSoundPlayer

    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var vertexBuffer: MTLBuffer!
    var indexBuffer: MTLBuffer!
    var texture: MTLTexture!
    var samplerState: MTLSamplerState!

    var vertices: [SlimeVertex] = []
    var indices: [UInt16] = []
    var touchInputs: [SlimeTouch] = []
    var touchStartTimes: [ObjectIdentifier: TimeInterval] = [:]
    var viewSize: CGSize = .zero
    var time: Float = 0

    private let cols = 60
    private let rows = 60

    init(type: SlimeType) {
        self.config = type.config
        self.soundPlayer = SlimeSoundPlayer(profile: config.soundProfile)
        super.init()

        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            fatalError("❌ Metal initialization failed")
        }
        self.device = device
        self.commandQueue = commandQueue

        let library = device.makeDefaultLibrary()!
        let vertexFunc = library.makeFunction(name: "slime_vertex")!
        let fragmentFunc = library.makeFunction(name: "slime_fragment")!

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SlimeVertex>.stride

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunc
        pipelineDescriptor.fragmentFunction = fragmentFunc
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        self.pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)

        loadTexture(named: type.textureName)
        setupSampler()
    }

    func loadTexture(named name: String) {
        let loader = MTKTextureLoader(device: device)
        let options: [MTKTextureLoader.Option: Any] = [
            .textureUsage: MTLTextureUsage.shaderRead.rawValue,
            .generateMipmaps: true,
            .SRGB: false,
            .origin: MTKTextureLoader.Origin.bottomLeft
        ]
        texture = try! loader.newTexture(name: name, scaleFactor: 1.0, bundle: nil, options: options)
    }

    func setupSampler() {
        let desc = MTLSamplerDescriptor()
        desc.minFilter = .linear
        desc.magFilter = .linear
        desc.mipFilter = .linear
        desc.rAddressMode = .clampToEdge
        desc.sAddressMode = .clampToEdge
        desc.tAddressMode = .clampToEdge
        samplerState = device.makeSamplerState(descriptor: desc)
    }

    func buildGrid() {
        vertices.removeAll()
        indices.removeAll()
        let padding: Float = 0.15
        for row in 0..<rows {
            for col in 0..<cols {
                let x = Float(col) / Float(cols - 1)
                let y = Float(row) / Float(rows - 1)
                let pos = SIMD2<Float>((x * 2 - 1) * (1 + padding), (y * 2 - 1) * (1 + padding))
                let uv = SIMD2<Float>(x, y)
                vertices.append(SlimeVertex(position: pos, uv: uv, original: pos))
            }
        }
        for row in 0..<(rows - 1) {
            for col in 0..<(cols - 1) {
                let i = UInt16(row * cols + col)
                let r = UInt16(row * cols + col + 1)
                let d = UInt16((row + 1) * cols + col)
                let rd = UInt16((row + 1) * cols + col + 1)
                indices += [i, d, r, r, d, rd]
            }
        }
        vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<SlimeVertex>.stride * vertices.count, options: [])
        indexBuffer = device.makeBuffer(bytes: indices, length: MemoryLayout<UInt16>.stride * indices.count, options: [])
    }

    func updateVertices() {
        let now = CACurrentMediaTime()

        // 튜닝 파라미터
        let restoreRate: Float = 0.18
        let pullLimit: Float = 0.014
        let falloffPower: Float = 2.5
        let minForce: Float = 0.2
        let waveSpeed: Float = 3.5           // 눌렀을 때 퍼지는 파동 속도
        let waveStrength: Float = 0.008      // 여운 파동 강도
        let pulseStrength: Float = 0.012     // 순간 움찔 효과 강도

        for i in 0..<vertices.count {
            var v = vertices[i]

            // 1. 기본 복원
            v.position = mix(v.position, v.original, t: SIMD2(repeating: restoreRate))

            // 2. 터치 기반 변형
            for touch in touchInputs {
                let dist = simd_distance(v.position, touch.position)
                if dist > 0.8 { continue }

                let force = max(touch.force, minForce)
                let duration = Float(now - (touchStartTimes[touch.id] ?? now))

                // (1) 기본 끌림 방향
                let dragDir: SIMD2<Float>
                if let prev = touch.previousPosition {
                    let drag = touch.position - prev
                    dragDir = simd_normalize(drag)
                } else {
                    dragDir = simd_normalize(v.position - touch.position)
                }

                // (2) falloff 적용
                let falloff = exp(-pow(dist / 0.3, falloffPower))
                let boost = min(duration * 0.5, 0.8)
                let pullOffset = dragDir * pullLimit * falloff * boost * sqrt(force)
                v.position += pullOffset

                // (3) 눌렀을 때 움찔 효과 (반대 방향 push)
                if duration < 0.15 {
                    let repelDir = simd_normalize(v.position - touch.position)
                    let pulseFalloff = exp(-pow(dist / 0.4, 2.2))
                    let pulseOffset = repelDir * pulseStrength * pulseFalloff * force
                    v.position += pulseOffset
                }

                // (4) 퍼지는 wave (여운)
                let wavePhase = sin(dist * 10.0 - duration * waveSpeed)
                let waveFalloff = exp(-pow(dist / 0.35, 2.5))
                let waveOffset = simd_normalize(v.original - touch.position) * waveStrength * wavePhase * waveFalloff * force
                v.position += waveOffset
            }

            vertices[i] = v
        }

        memcpy(vertexBuffer.contents(), vertices, MemoryLayout<SlimeVertex>.stride * vertices.count)
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor else { return }

        updateVertices()
        time += 1 / Float(view.preferredFramesPerSecond)

        var touchData: [SIMD3<Float>] = Array(repeating: SIMD3<Float>(-10, -10, 0), count: 5)
        for i in 0..<min(5, touchInputs.count) {
            let input = touchInputs[i]
            touchData[i] = SIMD3<Float>(input.position.x, input.position.y, input.force)
        }
        var maxTouches = min(touchInputs.count, 5)
        var currentTime = time
        var deform = config.deformation.toMetalStruct()

        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.setFragmentSamplerState(samplerState, index: 0)
        encoder.setFragmentBytes(&currentTime, length: MemoryLayout<Float>.stride, index: 1)
        encoder.setFragmentBytes(&touchData, length: MemoryLayout<SIMD3<Float>>.stride * 5, index: 2)
        encoder.setFragmentBytes(&maxTouches, length: MemoryLayout<Int>.stride, index: 3)
        encoder.setFragmentBytes(&deform, length: MemoryLayout<DeformationParams>.stride, index: 4)
        encoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewSize = size
        buildGrid()
    }

    func handleTouches(_ touches: Set<UITouch>, in view: UIView) {
        let now = CACurrentMediaTime()
        var updated: [ObjectIdentifier: SlimeTouch] = [:]
        var existing = Dictionary(uniqueKeysWithValues: touchInputs.map { ($0.id, $0) })
        for touch in touches {
            let id = ObjectIdentifier(touch)
            let loc = touch.location(in: view)
            let x = (Float(loc.x) / Float(view.bounds.width)) * 2.0 - 1.0
            let y = (1.0 - Float(loc.y) / Float(view.bounds.height)) * 2.0 - 1.0
            let pos = SIMD2<Float>(x, y)
            let rawForce = touch.force
            let maxForce = touch.maximumPossibleForce
            let normalizedForce = (maxForce > 0) ? Float(rawForce / maxForce) : 1.0
            let force = powf(normalizedForce, 0.8) * 1.2
            if pos.x.isFinite && pos.y.isFinite {
                let previous = existing[id]?.position
                updated[id] = SlimeTouch(id: id, position: pos, force: force, previousPosition: previous)
                if touchStartTimes[id] == nil {
                    touchStartTimes[id] = now
                    soundPlayer.play(type: .tap)
                }
            }
        }
        touchInputs = Array(updated.values)
    }
}
