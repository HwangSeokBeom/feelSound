//
//  SlimeRenderer.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/21/25.
//

import Foundation
import MetalKit
import simd

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
}

class SlimeRenderer: NSObject, MTKViewDelegate {
    private let config: SlimeConfig
    private let device: MTLDevice
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    private var indexBuffer: MTLBuffer!
    private var texture: MTLTexture!
    private var samplerState: MTLSamplerState!

    private var vertices: [SlimeVertex] = []
    private var indices: [UInt16] = []
    private var touchInputs: [SlimeTouch] = []
    private var viewSize: CGSize = .zero

    init(config: SlimeConfig, device: MTLDevice) {
        self.config = config
        self.device = device
        super.init()
        setupMetal()
    }

    func setupMetal() {
        commandQueue = device.makeCommandQueue()

        let library = device.makeDefaultLibrary()
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "slime_vertex")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "slime_fragment")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SlimeVertex>.stride
        pipelineDescriptor.vertexDescriptor = vertexDescriptor

        pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)

        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerState = device.makeSamplerState(descriptor: samplerDescriptor)

        texture = try? TextureLoader.loadTexture(name: config.textureName, device: device)
    }

    func buildGrid(cols: Int = 40, rows: Int = 40, size: CGSize) {
        viewSize = size
        vertices.removeAll()
        indices.removeAll()

        for y in 0..<rows {
            for x in 0..<cols {
                let u = Float(x) / Float(cols - 1)
                let v = Float(y) / Float(rows - 1)
                let px = u * Float(size.width)
                let py = v * Float(size.height)
                vertices.append(SlimeVertex(position: [px, py], uv: [u, v], original: [px, py]))
            }
        }

        for y in 0..<rows - 1 {
            for x in 0..<cols - 1 {
                let i = UInt16(y * cols + x)
                indices.append(contentsOf: [i, i+1, i+UInt16(cols)])
                indices.append(contentsOf: [i+1, i+1+UInt16(cols), i+UInt16(cols)])
            }
        }

        vertexBuffer = device.makeBuffer(length: MemoryLayout<SlimeVertex>.stride * vertices.count, options: [])
        indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.stride, options: [])
    }

    func updateVertices() {
        for i in 0..<vertices.count {
            var vertex = vertices[i]
            let displacement = vertex.original - vertex.position
            var velocity = vertex.velocity + displacement * config.elasticity
            velocity *= config.damping

            for touch in touchInputs {
                let dist = simd_distance(vertex.position, touch.position)
                if dist < 80 {
                    let dir = vertex.position - touch.position
                    let influence = (1 - dist / 80) * touch.force
                    velocity += dir * influence * 0.04
                }
            }

            vertex.position += velocity
            vertex.velocity = velocity
            vertices[i] = vertex
        }

        let pointer = vertexBuffer.contents().bindMemory(to: SlimeVertex.self, capacity: vertices.count)
        pointer.assign(from: vertices, count: vertices.count)
    }

    func draw(in view: MTKView) {
        updateVertices()

        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.setFragmentSamplerState(samplerState, index: 0)
        encoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        buildGrid(size: size)
    }

    func updateTouches(_ touches: [SlimeTouch]) {
        touchInputs = touches
    }
} 
