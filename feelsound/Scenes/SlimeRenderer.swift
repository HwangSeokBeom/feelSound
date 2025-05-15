////
////  Untitled.swift
////  feelsound
////
////  Created by Hwangseokbeom on 5/15/25.
////
//
//import Foundation
//import MetalKit
//import AVFoundation
//
//// MARK: - 슬라임 정점 및 터치 정의
//struct SlimeVertex {
//    var position: SIMD2<Float>
//    var uv: SIMD2<Float>
//    var original: SIMD2<Float>
//    var velocity: SIMD2<Float> = .zero
//    var force: SIMD2<Float> = .zero
//    var neighbors: [Int] = []
//}
//
//struct SlimeTouch {
//    let id: ObjectIdentifier
//    let position: SIMD2<Float>
//    let force: Float
//    var previousPosition: SIMD2<Float>?
//}
//
//// MARK: - 슬라임 사운드 플레이어
//class SlimeSoundPlayer {
//    private let engine = AVAudioEngine()
//    private var sourceNode: AVAudioSourceNode!
//    private var sampleRate: Float = 44100
//    private var time: Float = 0
//
//    init() {
//        setupEngine()
//    }
//
//    private func setupEngine() {
//        let mainMixer = engine.mainMixerNode
//        sampleRate = Float(engine.outputNode.outputFormat(forBus: 0).sampleRate)
//
//        sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
//            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
//            for frame in 0..<Int(frameCount) {
//                let sampleVal = sin(2.0 * .pi * 440 * self.time / self.sampleRate)
//                self.time += 1
//                for buffer in ablPointer {
//                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
//                    buf[frame] = sampleVal * 0.2
//                }
//            }
//            return noErr
//        }
//
//        engine.attach(sourceNode)
//        engine.connect(sourceNode, to: mainMixer, format: nil)
//        try? engine.start()
//    }
//
//    func play() {
//        time = 0
//    }
//}
//
//// MARK: - 슬라임 렌더러
//class SlimeRenderer: NSObject, MTKViewDelegate {
//    // 기본 Metal
//    var device: MTLDevice!
//    var commandQueue: MTLCommandQueue!
//    var pipelineState: MTLRenderPipelineState!
//    var vertexBuffer: MTLBuffer!
//    var indexBuffer: MTLBuffer!
//    var texture: MTLTexture!
//    var samplerState: MTLSamplerState!
//    
//    private var uTime: Float = 0
//    private var uTimeBuffer: MTLBuffer!
//    private var touchInputBuffer: MTLBuffer!
//    private var maxTouchesBuffer: MTLBuffer!
//
//    // 데이터
//    var vertices: [SlimeVertex] = []
//    var indices: [UInt16] = []
//    var touchInputs: [SlimeTouch] = []
//    var touchStartTimes: [ObjectIdentifier: TimeInterval] = [:]
//    var viewSize: CGSize = .zero
//
//    // 사운드
//    let soundPlayer = SlimeSoundPlayer()
//
//    // 초기화
//    override init() {
//        super.init()
//        self.device = MTLCreateSystemDefaultDevice()
//        self.commandQueue = device.makeCommandQueue()
//
//        //  초기 버퍼 생성 (기본 사이즈 확보)
//        uTimeBuffer = device.makeBuffer(length: MemoryLayout<Float>.size, options: [])
//        touchInputBuffer = device.makeBuffer(length: MemoryLayout<SIMD3<Float>>.stride * 10, options: [])
//        maxTouchesBuffer = device.makeBuffer(length: MemoryLayout<Int32>.size, options: [])
//    }
//
//    // Grid 설정 (외부에서 호출)
//    func buildGrid() {
//        // 기본 정점, 인덱스 세팅 (예시)
//        vertices.removeAll()
//        indices.removeAll()
//
//        let cols = 40
//        let rows = 40
//
//        for y in 0..<rows {
//            for x in 0..<cols {
//                let pos = SIMD2<Float>(
//                    Float(x) / Float(cols - 1) * Float(viewSize.width),
//                    Float(y) / Float(rows - 1) * Float(viewSize.height)
//                )
//                let uv = SIMD2<Float>(Float(x) / Float(cols - 1), Float(y) / Float(rows - 1))
//                vertices.append(SlimeVertex(position: pos, uv: uv, original: pos))
//            }
//        }
//
//        for y in 0..<rows-1 {
//            for x in 0..<cols-1 {
//                let i = UInt16(y * cols + x)
//                indices.append(contentsOf: [i, i+1, i+UInt16(cols), i+1, i+UInt16(cols)+1, i+UInt16(cols)])
//            }
//        }
//
//        // 버퍼 생성
//        vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<SlimeVertex>.stride * vertices.count, options: [])
//        indexBuffer = device.makeBuffer(bytes: indices, length: MemoryLayout<UInt16>.stride * indices.count, options: [])
//
//        // 텍스처 로드
//        let textureLoader = MTKTextureLoader(device: device)
//            if let url = Bundle.main.url(forResource: "glitter_slime", withExtension: "png") {
//                texture = try? textureLoader.newTexture(URL: url, options: nil)
//            } else {
//                print("❗ glitter_slime.png 이미지가 번들에 없습니다.")
//            }
//
//            guard let library = device.makeDefaultLibrary() else {
//                fatalError("❌ Metal 라이브러리 로딩 실패")
//            }
//            guard let vertexFunc = library.makeFunction(name: "slime_vertex") else {
//                fatalError("❌ slime_vertex 함수 없음")
//            }
//            guard let fragmentFunc = library.makeFunction(name: "slime_fragment") else {
//                fatalError("❌ slime_fragment 함수 없음")
//            }
//
//            let descriptor = MTLRenderPipelineDescriptor()
//            descriptor.vertexFunction = vertexFunc
//            descriptor.fragmentFunction = fragmentFunc
//            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
//
//            do {
//                pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
//            } catch {
//                fatalError("❌ RenderPipelineState 생성 실패: \(error)")
//            }
//        }
//
//    // MARK: - Touch 처리
//    func handleTouches(_ touches: Set<UITouch>, in view: UIView) {
//        for touch in touches {
//            let id = ObjectIdentifier(touch)
//            let location = touch.location(in: view)
//            let pos = SIMD2<Float>(Float(location.x), Float(location.y))
//            let force = Float(touch.force / touch.maximumPossibleForce)
//            let previous = touch.previousLocation(in: view)
//            let prevPos = SIMD2<Float>(Float(previous.x), Float(previous.y))
//            let slimeTouch = SlimeTouch(id: id, position: pos, force: force, previousPosition: prevPos)
//
//            if let index = touchInputs.firstIndex(where: { $0.id == id }) {
//                touchInputs[index] = slimeTouch
//            } else {
//                touchInputs.append(slimeTouch)
//                soundPlayer.play()
//            }
//        }
//    }
//
//    // MARK: - MTKViewDelegate
//    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
//        viewSize = size
//    }
//
//    func draw(in view: MTKView) {
//        guard let drawable = view.currentDrawable,
//              let descriptor = view.currentRenderPassDescriptor else { return }
//
//        // ✅ 시간 업데이트
//        uTime += 1.0 / 60.0
//        memcpy(uTimeBuffer.contents(), &uTime, MemoryLayout<Float>.size)
//
//        // ✅ 터치 데이터를 float3 배열로 변환
//        var touches: [SIMD3<Float>] = touchInputs.map {
//            SIMD3<Float>($0.position.x, $0.position.y, $0.force)
//        }
//
//        // 최대 10개까지만
//        if touches.count > 10 {
//            touches = Array(touches.prefix(10))
//        }
//
//        // ✅ 터치 버퍼 복사
//        memcpy(touchInputBuffer.contents(), touches, MemoryLayout<SIMD3<Float>>.stride * touches.count)
//
//        // ✅ 터치 개수 복사
//        var maxTouches: Int32 = Int32(touches.count)
//        memcpy(maxTouchesBuffer.contents(), &maxTouches, MemoryLayout<Int32>.size)
//
//        // 커맨드 구성
//        let commandBuffer = commandQueue.makeCommandBuffer()!
//        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
//
//        encoder.setRenderPipelineState(pipelineState)
//        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
//
//        encoder.setFragmentTexture(texture, index: 0)
//        encoder.setFragmentSamplerState(samplerState, index: 0)
//
//        // ✅ 새 버퍼 바인딩
//        encoder.setFragmentBuffer(uTimeBuffer, offset: 0, index: 1)
//        encoder.setFragmentBuffer(touchInputBuffer, offset: 0, index: 2)
//        encoder.setFragmentBuffer(maxTouchesBuffer, offset: 0, index: 3)
//
//        encoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
//
//        encoder.endEncoding()
//        commandBuffer.present(drawable)
//        commandBuffer.commit()
//    }
//}
