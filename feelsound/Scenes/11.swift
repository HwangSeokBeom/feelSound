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

    private let cols = 40
    private let rows = 40

    init(type: SlimeType) {
        self.config = type.config
        self.soundPlayer = SlimeSoundPlayer(profile: config.soundProfile)
        super.init()

        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            fatalError("❌ Metal 초기화 실패")
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

        self.pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)

        loadTexture(named: type.textureName)
        setupSampler()
    }

    func loadTexture(named name: String) {
        let loader = MTKTextureLoader(device: device)

        do {
            texture = try loader.newTexture(name: name, scaleFactor: 1.0, bundle: nil, options: [
                MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.bottomLeft
            ])
        } catch {
            fatalError("❌ '\(name)' 텍스처 로딩 실패: \(error.localizedDescription)")
        }
    }

    func setupSampler() {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerState = device.makeSamplerState(descriptor: samplerDescriptor)
    }

    func buildGrid() {
        vertices.removeAll()
        indices.removeAll()

        let padding: Float = 0.1 // 👈 화면보다 5% 크게

        for row in 0..<rows {
            for col in 0..<cols {
                let x = Float(col) / Float(cols - 1)
                let y = Float(row) / Float(rows - 1)
                
                // 👇 padding을 곱해 위치를 살짝 확장
                let pos = SIMD2<Float>(
                    (x * 2 - 1) * (1 + padding),
                    (y * 2 - 1) * (1 + padding)
                )
                let uv = SIMD2<Float>(x, y)
                vertices.append(SlimeVertex(position: pos, uv: uv, original: pos))
            }
        }

        for row in 0..<(rows - 1) {
            for col in 0..<(cols - 1) {
                let topLeft = UInt16(row * cols + col)
                let topRight = UInt16(row * cols + col + 1)
                let bottomLeft = UInt16((row + 1) * cols + col)
                let bottomRight = UInt16((row + 1) * cols + col + 1)
                indices.append(contentsOf: [topLeft, bottomLeft, topRight])
                indices.append(contentsOf: [topRight, bottomLeft, bottomRight])
            }
        }

        vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<SlimeVertex>.stride * vertices.count,
            options: []
        )
        indexBuffer = device.makeBuffer(
            bytes: indices,
            length: MemoryLayout<UInt16>.stride * indices.count,
            options: []
        )
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
            let force = (maxForce > 0) ? Float(rawForce / maxForce) : 1.0

            if pos.x.isFinite && pos.y.isFinite {
                let previous = existing[id]?.position
                updated[id] = SlimeTouch(id: id, position: pos, force: force, previousPosition: previous)
                if touchStartTimes[id] == nil {
                    touchStartTimes[id] = now
                }
            }
        }

        touchInputs = Array(updated.values)
    }

    func updateVertices() {
        let now = CACurrentMediaTime()

        for i in 0..<vertices.count {
            var v = vertices[i]
            let delta = v.original - v.position
            v.velocity += delta * config.elasticity

            for touch in touchInputs {
                let dist = simd_distance(v.position, touch.position)
                let duration = Float(now - (touchStartTimes[touch.id] ?? now))
                let boost = min(duration, 2.0) / 2.0
                let radius = 0.25 + 0.15 * boost

                if dist < radius + 0.1 {
                    let pull = (radius + 0.1 - dist) * (0.04 + 0.08 * touch.force)
                    v.velocity += simd_normalize(v.position - touch.position) * pull
                }

                if dist < radius {
                    let pressure = (radius - dist) * touch.force * 0.2
                    v.position += simd_normalize(touch.position - v.position) * pressure * boost

                    if simd_length(v.original - v.position) > 0.05 && i % 50 == 0 {
                        if duration < 0.08 {
                            soundPlayer.play(type: .tap)
                        } else if let prev = touch.previousPosition {
                            let move = simd_length(touch.position - prev)
                            let velocity = min(move * 15.0, 1.0)
                            if velocity > 0.15 {
                                soundPlayer.play(type: .drag, velocity: velocity)
                            } else {
                                soundPlayer.play(type: .press, duration: duration)
                            }
                        } else {
                            soundPlayer.play(type: .press, duration: duration)
                        }
                    }
                }
            }

            v.velocity *= config.damping
            v.position += v.velocity
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

        var maxTouches = 5
        var currentTime = time

        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.setFragmentSamplerState(samplerState, index: 0)
        encoder.setFragmentBytes(&touchData, length: MemoryLayout<SIMD3<Float>>.stride * 5, index: 2)
        encoder.setFragmentBytes(&maxTouches, length: MemoryLayout<Int>.stride, index: 3)
        encoder.setFragmentBytes(&currentTime, length: MemoryLayout<Float>.stride, index: 1)
        encoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewSize = size
        buildGrid()
    }
}
