//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/13/25.
//

import MetalKit

class SlimeMetalRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState!

    private var vertexBuffer: MTLBuffer!
    private var uniformBuffer: MTLBuffer!
    private var vertexCount: Int = 0

    struct Vertex {
        var position: SIMD2<Float>
    }

    struct Uniforms {
        var touchPosition: SIMD2<Float>
        var radius: Float
    }

    private var uniforms = Uniforms(touchPosition: .zero, radius: 0.3)

    private weak var metalView: MTKView?

    init(metalView: MTKView) {
        guard let device = metalView.device else {
            fatalError("Metal device not found")
        }
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        self.metalView = metalView

        super.init()
        metalView.delegate = self
        buildPipeline(view: metalView)
        createSlimeMesh()
    }

    private func buildPipeline(view: MTKView) {
        let library = device.makeDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")

        // ✅ 1. Vertex Descriptor 정의
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2           // position: float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        // ✅ 2. 파이프라인 디스크립터 설정
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        descriptor.vertexDescriptor = vertexDescriptor   // <-- 꼭 필요함!

        pipelineState = try! device.makeRenderPipelineState(descriptor: descriptor)
    }

    private func createSlimeMesh() {
        let meshSize = 40
        var vertices: [Vertex] = []

        for i in 0..<meshSize {
            for j in 0..<meshSize {
                let x = Float(j) / Float(meshSize - 1) * 2.0 - 1.0 // [-1, 1]
                let y = Float(i) / Float(meshSize - 1) * 2.0 - 1.0
                vertices.append(Vertex(position: SIMD2<Float>(x, y)))
            }
        }

        vertexCount = vertices.count
        vertexBuffer = device.makeBuffer(bytes: vertices,
                                         length: MemoryLayout<Vertex>.stride * vertices.count,
                                         options: [])
    }

    func updateTouch(location: CGPoint) {
        guard let view = metalView else { return }

        // SpriteKit → Metal 좌표계 변환
        let x = Float((location.x / view.bounds.width) * 2 - 1)
        let y = Float(((view.bounds.height - location.y) / view.bounds.height) * 2 - 1)

        uniforms.touchPosition = SIMD2<Float>(x, y)
        uniforms.radius = 0.3

        uniformBuffer = device.makeBuffer(bytes: &uniforms,
                                          length: MemoryLayout<Uniforms>.stride,
                                          options: [])
    }

    func update() {
        // 현재는 필요 없음
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        // 🧩 바인딩할 유니폼 버퍼가 있는 경우에만 연결
        if let uniformBuffer = uniformBuffer {
            encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        } else {
            // 🛑 유니폼이 없으면 빈 버퍼라도 생성해서 바인딩
            var defaultUniforms = Uniforms(touchPosition: .zero, radius: 0.0)
            let fallbackBuffer = device.makeBuffer(bytes: &defaultUniforms,
                                                   length: MemoryLayout<Uniforms>.stride,
                                                   options: [])
            encoder.setVertexBuffer(fallbackBuffer, offset: 0, index: 1)
        }

        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Not needed for now
    }
}
