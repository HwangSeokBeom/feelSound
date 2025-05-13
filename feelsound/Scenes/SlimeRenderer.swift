//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/13/25.
//

import Foundation
import MetalKit

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
    var touchPosition: SIMD2<Float> = SIMD2<Float>(-10, -10)
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

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        let loc = gesture.location(in: view)

        // 정확한 Metal 좌표계로 변환
        let x = (Float(loc.x) / Float(view.bounds.width)) * 2.0 - 1.0
        let y = (1.0 - Float(loc.y) / Float(view.bounds.height)) * 2.0 - 1.0  // ✅ 상하 반전!

        touchPosition = SIMD2<Float>(x, y)
    }

    func updateVertices() {
        for i in 0..<vertices.count {
            var v = vertices[i]
            let delta = v.original - v.position
            let restoringForce = delta * 0.1       // 복원력 강화
            let damping: Float = 0.85              // 감쇠 낮춤

            v.velocity += restoringForce

            let dist = simd_distance(v.position, touchPosition)
            if dist < 0.4 {
                let pull = (0.4 - dist) * 0.03     // 터치 반응 증가
                let dir = simd_normalize(v.position - touchPosition)
                v.velocity += dir * pull
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
        var touch = touchPosition
        var currentTime = time

        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        encoder.setFragmentTexture(texture, index: 0)
        encoder.setFragmentSamplerState(samplerState, index: 0)
        encoder.setFragmentBytes(&touch, length: MemoryLayout<SIMD2<Float>>.stride, index: 0)
        encoder.setFragmentBytes(&currentTime, length: MemoryLayout<Float>.stride, index: 1)

        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: indices.count,
            indexType: .uint16,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0
        )

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewSize = size
        buildGrid()
    }
}
