//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/13/25.
//

// SlimeRenderer.swift
// feelsound

import Foundation
import MetalKit

struct SlimeVertex {
    var position: SIMD2<Float>
    var uv: SIMD2<Float>
    var original: SIMD2<Float>
    var velocity: SIMD2<Float> = .zero
}

class SlimeRenderer: NSObject, MTKViewDelegate {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var vertexBuffer: MTLBuffer!
    var indexBuffer: MTLBuffer!

    var texture: MTLTexture!
    var samplerState: MTLSamplerState!

    var vertices: [SlimeVertex] = []
    var indices: [UInt16] = []

    var touchInputs: [(position: SIMD2<Float>, force: Float)] = []
    var time: Float = 0
    var viewSize: CGSize = .zero

    private let cols = 40
    private let rows = 40

    override init() {
        super.init()
        self.device = MTLCreateSystemDefaultDevice()
        self.commandQueue = device.makeCommandQueue()

        let library = device.makeDefaultLibrary()!
        let vertexFunc = library.makeFunction(name: "slime_vertex")
        let fragmentFunc = library.makeFunction(name: "slime_fragment")

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<SlimeVertex>.stride
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunc
        descriptor.fragmentFunction = fragmentFunc
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.vertexDescriptor = vertexDescriptor

        self.pipelineState = try! device.makeRenderPipelineState(descriptor: descriptor)

        loadTexture(named: "glitter_slime")
        setupSampler()
    }

    func loadTexture(named name: String) {
        let loader = MTKTextureLoader(device: device)
        let url = Bundle.main.url(forResource: name, withExtension: "png")!
        texture = try! loader.newTexture(URL: url, options: nil)
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

        for row in 0..<rows {
            for col in 0..<cols {
                let x = Float(col) / Float(cols - 1)
                let y = Float(row) / Float(rows - 1)
                let pos = SIMD2<Float>(x * 2 - 1, y * 2 - 1)
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

        vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<SlimeVertex>.stride * vertices.count, options: [])
        indexBuffer = device.makeBuffer(bytes: indices, length: MemoryLayout<UInt16>.stride * indices.count, options: [])
    }

    func handleTouches(_ touches: Set<UITouch>, in view: UIView) {
        touchInputs.removeAll()
        for touch in touches {
            let loc = touch.location(in: view)
            let x = (Float(loc.x) / Float(view.bounds.width)) * 2.0 - 1.0
            let y = (1.0 - Float(loc.y) / Float(view.bounds.height)) * 2.0 - 1.0
            let pos = SIMD2<Float>(x, y)

            let rawForce = touch.force
            let maxForce = touch.maximumPossibleForce
            let force = (maxForce > 0) ? Float(rawForce / maxForce) : 1.0

            if pos.x.isFinite && pos.y.isFinite {
                touchInputs.append((position: pos, force: force))
            }
        }
    }
    
    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        guard let view = sender.view else { return }
        let location = sender.location(in: view)

        // 터치처럼 처리되도록 좌표를 Metal 좌표계로 변환
        let x = (Float(location.x) / Float(view.bounds.width)) * 2.0 - 1.0
        let y = (1.0 - Float(location.y) / Float(view.bounds.height)) * 2.0 - 1.0
        let position = SIMD2<Float>(x, y)

        let force: Float
        if #available(iOS 9.0, *), sender.numberOfTouches > 0 {
            // 첫 번째 터치 force 사용 (없으면 1.0로 fallback)
            if let touch = (sender.view as? MTKView)?.gestureRecognizers?
                .compactMap({ $0 as? UIGestureRecognizer })
                .compactMap({ $0 as? UITouch })
                .first {
                force = Float(touch.force / touch.maximumPossibleForce)
            } else {
                force = 1.0
            }
        } else {
            force = 1.0
        }

        // 터치 데이터 등록
        touchInputs = [(position: position, force: force)]
    }

    func updateVertices() {
        for i in 0..<vertices.count {
            var v = vertices[i]
            let delta = v.original - v.position
            let restoringForce = delta * 0.1
            let damping: Float = 0.85

            v.velocity += restoringForce

            for (touchPos, force) in touchInputs {
                let dist = simd_distance(v.position, touchPos)
                if dist < 0.4 {
                    let pull = (0.4 - dist) * (0.02 + 0.05 * force)
                    let dir = simd_normalize(v.position - touchPos)
                    v.velocity += dir * pull
                }

                if force > 0.8 && dist < 0.3 {
                    v.position += simd_normalize(touchPos - v.position) * 0.01
                }
            }

            v.velocity *= damping
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
