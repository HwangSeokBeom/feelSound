//
//  ColoringView.swift
//  feelsound
//
//  Created by 안준경 on 5/21/25.
//

import SwiftUI

struct ColoringView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var floodFillImage: UIImage?
    @State private var selectedColor: Color = .red
    @State private var showingColorPicker = false
    @State private var isDrawing = false
    @State private var currentAreaMask: [[Bool]]? = nil // 현재 영역을 추적하는 마스크
    @State private var showColorPalette = false // 컬러 팔레트 모달을 제어하는 상태
    @State private var paletteHeight: CGFloat = 50 // 기본 모달 높이
    private let collapsedPaletteHeight: CGFloat = 80 // 접힌 상태 높이
    private let expandedPaletteHeight: CGFloat = 200 // 펼친 상태 높이
    
    @State private var previousDrawPoint: CGPoint? = nil


    
    // 사용 가능한 색상 팔레트
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        dismiss()
                    }, label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width:20, height:20)
                            .foregroundColor(.white)
                    })
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            
                        }, label: {
                            VStack {
                                Image(systemName: "arrowshape.turn.up.left.fill")
                                    .resizable()
                                    .frame(width: 24, height: 18)
                                Text("undo")
                            }.foregroundColor(.white)
                        })
                        
                        Button(action: {
                            
                        }, label: {
                            VStack {
                                Image(systemName: "arrowshape.turn.up.right.fill")
                                    .resizable()
                                    .frame(width: 24, height: 18)
                                Text("redo")
                            }.foregroundColor(.white)
                        })
                        
                        Button(action: {
                            
                        }, label: {
                            VStack {
                                Image(systemName: "pencil.line")
                                    .resizable()
                                    .frame(width: 24, height: 18)
                                Text("stroke")
                            }.foregroundColor(.white)
                        })
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        
                    }, label: {
                        Text("Done")
                            .bold()
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    })
                }
                .padding(20)
                
                VStack{
                    // 색칠할 이미지
                    if let floodFillImage = floodFillImage {
                        DrawableImageView(image: floodFillImage, onDraw: handleDraw, onDrawingStateChanged: handleDrawingStateChanged)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(contentMode: .fit)
                            .background(Color.white)
                    } else {
                        if let image = UIImage(named: "panda") {
                            DrawableImageView(image: image, onDraw: handleDraw, onDrawingStateChanged: handleDrawingStateChanged)
                                .frame(maxWidth: .infinity)
                                .aspectRatio(contentMode: .fit)
                                .background(Color.white)
                                .onAppear(perform: initializeImage)
                        } else {
                            Text("이미지를 찾을 수 없습니다")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 40)
                .background(Color.gray)
                
                Spacer()
            }
            .background(.black)
            .padding(.bottom, 0)
            
            // 컬러 팔레트 모달
            VStack {
                Spacer()
                
                // 모달 팔레트
                VStack(spacing: 0) {
                    // 토글 버튼만 있는 헤더
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                showColorPalette.toggle()
                                paletteHeight = showColorPalette ? expandedPaletteHeight : collapsedPaletteHeight
                            }
                        }) {
                            Image(systemName: showColorPalette ? "chevron.down" : "chevron.up")
                                .resizable()
                                .foregroundColor(.white)
                                .frame(width: 20,
                                       height: 14)
                        }
                        .padding(.top, -20) // 토글 버튼을 모달 위로 올림
                        
                        Spacer()
                    }
                    .frame(height: 20) // 헤더 높이 축소
                    
                    // 확장된 상태일 때만 보이는 컨텐츠
                    if showColorPalette {
                        // 색상 팔레트
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 60), spacing: 0)
                        ], spacing: 10) {
                            ForEach(colors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(color == selectedColor ? Color.black : Color.clear, lineWidth: 3)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                            
                            // 사용자 정의 색상 선택 버튼
                            Circle()
                                .fill(Color.white)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "plus")
                                        .foregroundColor(.black)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                                .onTapGesture {
                                    showingColorPicker = true
                                }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 20)
                    }
                }
                .frame(height: paletteHeight)
                .background(Color.black)
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .shadow(radius: 5)
                .animation(.spring(), value: paletteHeight)
            }
            .edgesIgnoringSafeArea(.bottom)
            
            // 컬러 피커 시트
            .sheet(isPresented: $showingColorPicker) {
                ColorPicker("색상 선택", selection: $selectedColor)
                    .padding()
            }
        }
        .onAppear {
            // 초기 상태에서 모달의 헤더 부분만 표시
            paletteHeight = collapsedPaletteHeight
        }
    }
    
    // 이미지 초기화
    func initializeImage() {
        guard let originalImage = UIImage(named: "panda") else { return }
        floodFillImage = originalImage
    }
    
    // 드로잉을 위한 UIView
    struct DrawableImageView: UIViewRepresentable {
        var image: UIImage
        var onDraw: (CGPoint) -> Void
        var onDrawingStateChanged: (Bool) -> Void
        
        func makeUIView(context: Context) -> UIImageView {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.isUserInteractionEnabled = true
            
            // 드래그 제스처 추가
            let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
            imageView.addGestureRecognizer(panGesture)
            
            return imageView
        }
        
        func updateUIView(_ uiView: UIImageView, context: Context) {
            uiView.image = image
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject {
            var parent: DrawableImageView
            var lastPoint: CGPoint? // 이전 포인트 저장
            
            init(_ parent: DrawableImageView) {
                self.parent = parent
            }
            
            @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
                let location = gesture.location(in: gesture.view)
                
                guard let imageView = gesture.view as? UIImageView,
                      let image = imageView.image else { return }
                
                // 이미지뷰의 실제 이미지 프레임 계산 - 더 정확한 계산
                let viewSize = imageView.bounds.size
                let imageSize = image.size
                
                // 이미지가 실제로 그려지는 영역과 스케일 계산
                var imageFrame = CGRect.zero
                var scale: CGFloat = 1.0
                
                if imageSize.width / imageSize.height > viewSize.width / viewSize.height {
                    // 너비에 맞춰진 경우
                    scale = viewSize.width / imageSize.width
                    let scaledHeight = viewSize.width * (imageSize.height / imageSize.width)
                    imageFrame = CGRect(x: 0,
                                      y: (viewSize.height - scaledHeight) / 2,
                                      width: viewSize.width,
                                      height: scaledHeight)
                } else {
                    // 높이에 맞춰진 경우
                    scale = viewSize.height / imageSize.height
                    let scaledWidth = viewSize.height * (imageSize.width / imageSize.height)
                    imageFrame = CGRect(x: (viewSize.width - scaledWidth) / 2,
                                      y: 0,
                                      width: scaledWidth,
                                      height: viewSize.height)
                }
                
                // 터치 위치가 이미지 영역 안에 있는지 확인
                guard imageFrame.contains(location) else { return }
                
                // 이미지 내에서의 정규화된 좌표 계산 (0~1 범위)
                let normalizedX = (location.x - imageFrame.origin.x) / imageFrame.width
                let normalizedY = (location.y - imageFrame.origin.y) / imageFrame.height
                
                // 정규화된 좌표를 원본 이미지 픽셀 좌표로 변환
                let pixelX = normalizedX * imageSize.width
                let pixelY = normalizedY * imageSize.height
                
                let currentPoint = CGPoint(x: pixelX, y: pixelY)
                
                // 제스처 상태에 따라 드로잉 처리
                if gesture.state == .began {
                    parent.onDrawingStateChanged(true)
                    lastPoint = currentPoint
                    parent.onDraw(currentPoint)
                } else if gesture.state == .changed {
                    if let lastPoint = lastPoint {
                        interpolatePoints(from: lastPoint, to: currentPoint)
                    }
                    lastPoint = currentPoint
                } else if gesture.state == .ended || gesture.state == .cancelled {
                    parent.onDrawingStateChanged(false)
                    lastPoint = nil
                }
            }
            
            // 두 점 사이를 매우 촘촘하게 보간하는 함수
            private func interpolatePoints(from startPoint: CGPoint, to endPoint: CGPoint) {
                let distance = hypot(endPoint.x - startPoint.x, endPoint.y - startPoint.y)
                
                // 더 많은 점을 생성하도록 수정
                let numberOfPoints = max(Int(distance), 10) // 최소 10개 점으로 증가
                
                if numberOfPoints < 2 { // 거리가 너무 짧으면 중간점 생성 안함
                    parent.onDraw(endPoint)
                    return
                }
                
                for i in 1...numberOfPoints {
                    let ratio = CGFloat(i) / CGFloat(numberOfPoints)
                    let x = startPoint.x + (endPoint.x - startPoint.x) * ratio
                    let y = startPoint.y + (endPoint.y - startPoint.y) * ratio
                    let interpolatedPoint = CGPoint(x: x, y: y)
                    parent.onDraw(interpolatedPoint)
                }
            }
        }
    }
    
    // 드로잉 상태 변경 처리
    func handleDrawingStateChanged(_ isCurrentlyDrawing: Bool) {
        isDrawing = isCurrentlyDrawing
        
        // 드로잉이 끝나면 현재 영역 마스크 초기화
        if !isCurrentlyDrawing {
            currentAreaMask = nil
            previousDrawPoint = nil
        }
    }
    
    // 드로잉 처리
    func handleDraw(at location: CGPoint) {
        guard let currentImage = floodFillImage else { return }
        
        // 드로잉 색칠 실행
        DispatchQueue.global(qos: .userInitiated).async {
            let coloredImage: UIImage
            
            // 드로잉 시작 시 영역 마스크 생성
            if self.isDrawing && self.currentAreaMask == nil {
                // 현재 영역 마스크와 이미지 동시에 가져오기
                let (maskAndImage) = self.createAreaMask(image: currentImage, at: location)
                self.currentAreaMask = maskAndImage.0
                
                // 첫 번째 점은 점으로 그리기
                coloredImage = self.drawColor(image: maskAndImage.1, at: location, with: UIColor(self.selectedColor))
                self.previousDrawPoint = location
            } else if let previousPoint = self.previousDrawPoint {
                // 이전 점이 있으면 이전 점과 현재 점 사이에 선 그리기
                coloredImage = self.drawLine(image: currentImage, from: previousPoint, to: location, with: UIColor(self.selectedColor))
                self.previousDrawPoint = location
            } else {
                // 첫 점은 점으로 그리기
                coloredImage = self.drawColor(image: currentImage, at: location, with: UIColor(self.selectedColor))
                self.previousDrawPoint = location
            }
            
            DispatchQueue.main.async {
                self.floodFillImage = coloredImage
            }
        }
    }
    
    // 두 점 사이에 선을 그리는 함수
    func drawLine(image: UIImage, from startPoint: CGPoint, to endPoint: CGPoint, with color: UIColor) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let width = cgImage.width
        let height = cgImage.height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        let context = CGContext(data: nil,
                                width: width,
                                height: height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data else { return image }
        
        let pixelData = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
        
        // 새 색상 준비
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let newRed = UInt8(red * 255)
        let newGreen = UInt8(green * 255)
        let newBlue = UInt8(blue * 255)
        
        // 현재 영역 마스크가 없으면 새로 생성해야 함 (이 부분은 handleDraw에서 처리)
        guard let areaMask = currentAreaMask, isDrawing else {
            return image
        }
        
        // 브러시 크기
        let brushRadius = 5
        
        // 브레젠험 알고리즘을 사용하여 선 그리기
        let dx = abs(Int(endPoint.x) - Int(startPoint.x))
        let dy = abs(Int(endPoint.y) - Int(startPoint.y))
        let sx = Int(startPoint.x) < Int(endPoint.x) ? 1 : -1
        let sy = Int(startPoint.y) < Int(endPoint.y) ? 1 : -1
        var err = dx - dy
        
        var x = Int(startPoint.x)
        var y = Int(startPoint.y)
        
        while true {
            // 각 점에서 원형 브러시로 색칠
            for by in -brushRadius...brushRadius {
                for bx in -brushRadius...brushRadius {
                    // 원 내부만 색칠
                    if bx*bx + by*by > brushRadius*brushRadius {
                        continue
                    }
                    
                    let nx = x + bx
                    let ny = y + by
                    
                    // 이미지 범위 확인
                    if nx < 0 || nx >= width || ny < 0 || ny >= height {
                        continue
                    }
                    
                    // 현재 영역 마스크 확인 - 영역 내에 있는 픽셀만 색칠
                    if ny < areaMask.count && nx < areaMask[ny].count && areaMask[ny][nx] {
                        let offset = (ny * bytesPerRow) + (nx * bytesPerPixel)
                        
                        // 현재 픽셀 색상 확인 (검은색 선 위는 색칠하지 않음)
                        let currentRed = pixelData[offset]
                        let currentGreen = pixelData[offset + 1]
                        let currentBlue = pixelData[offset + 2]
                        
                        let isNotBlackLine = currentRed >= 30 || currentGreen >= 30 || currentBlue >= 30
                        
                        if isNotBlackLine {
                            // 색상 변경
                            pixelData[offset] = newRed
                            pixelData[offset + 1] = newGreen
                            pixelData[offset + 2] = newBlue
                        }
                    }
                }
            }
            
            // 종료 조건 확인
            if x == Int(endPoint.x) && y == Int(endPoint.y) {
                break
            }
            
            // 다음 점으로 이동
            let e2 = 2 * err
            if e2 > -dy {
                err -= dy
                x += sx
            }
            if e2 < dx {
                err += dx
                y += sy
            }
        }
        
        let newContext = CGContext(data: data,
                                   width: width,
                                   height: height,
                                   bitsPerComponent: bitsPerComponent,
                                   bytesPerRow: bytesPerRow,
                                   space: colorSpace,
                                   bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        guard let newCGImage = newContext.makeImage() else { return image }
        return UIImage(cgImage: newCGImage)
    }
    
    // 영역 마스크 생성 (Flood Fill 알고리즘 사용)
    func createAreaMask(image: UIImage, at point: CGPoint) -> ([[Bool]], UIImage) {
        guard let cgImage = image.cgImage else { return ([], image) }
        let width = cgImage.width
        let height = cgImage.height
        
        // 마스크 배열 초기화
        var mask = Array(repeating: Array(repeating: false, count: width), count: height)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        let context = CGContext(data: nil,
                                width: width,
                                height: height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data else { return (mask, image) }
        
        let pixelData = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
        
        let startX = Int(point.x)
        let startY = Int(point.y)
        
        // 범위 체크
        guard startX >= 0 && startX < width && startY >= 0 && startY < height else { return (mask, image) }
        
        // 시작 위치의 색상
        let startOffset = (startY * bytesPerRow) + (startX * bytesPerPixel)
        let startRed = pixelData[startOffset]
        let startGreen = pixelData[startOffset + 1]
        let startBlue = pixelData[startOffset + 2]
        
        // 검은색 선인지 확인 (RGB 값이 모두 낮으면 검은색으로 간주)
        let isBlackLine = startRed < 30 && startGreen < 30 && startBlue < 30
        if isBlackLine {
            print("검은 선 위를 선택했습니다. 마스크 생성 안함")
            return (mask, image)
        }
        
        // 플러드 필 알고리즘으로 영역 마스크 생성
        var queue = [(startX, startY)]
        var visited = Set<String>()
        
        print("영역 마스크 생성: 위치 (\(startX), \(startY)), 색상 RGB(\(startRed), \(startGreen), \(startBlue))")
        
        while !queue.isEmpty {
            let (x, y) = queue.removeFirst()
            let key = "\(x),\(y)"
            
            // 이미 방문한 픽셀은 건너뜀
            if visited.contains(key) {
                continue
            }
            
            visited.insert(key)
            
            let offset = (y * bytesPerRow) + (x * bytesPerPixel)
            
            // 픽셀이 범위를 벗어나면 건너뜀
            guard offset >= 0 && offset < width * height * bytesPerPixel - 3 else {
                continue
            }
            
            // 같은 색상 영역인지 확인 (색상 차이가 적으면 같은 색상으로 간주)
            let currentRed = pixelData[offset]
            let currentGreen = pixelData[offset + 1]
            let currentBlue = pixelData[offset + 2]
            
            let isSimilarToStartColor = abs(Int(currentRed) - Int(startRed)) < 30 &&
            abs(Int(currentGreen) - Int(startGreen)) < 30 &&
            abs(Int(currentBlue) - Int(startBlue)) < 30
            
            let isNotBlackLine = currentRed >= 30 || currentGreen >= 30 || currentBlue >= 30
            
            if isSimilarToStartColor && isNotBlackLine {
                // 마스크 설정
                mask[y][x] = true
                
                // 4방향 이웃 픽셀 큐에 추가
                let neighbors = [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]
                
                for (nx, ny) in neighbors {
                    if nx >= 0 && nx < width && ny >= 0 && ny < height {
                        queue.append((nx, ny))
                    }
                }
            }
        }
        
        return (mask, image)
    }
    
    // 드로잉 색칠 알고리즘 구현
    func drawColor(image: UIImage, at point: CGPoint, with color: UIColor) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let width = cgImage.width
        let height = cgImage.height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        let context = CGContext(data: nil,
                                width: width,
                                height: height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data else { return image }
        
        let pixelData = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
        
        let startX = Int(point.x)
        let startY = Int(point.y)
        
        // 범위 체크
        guard startX >= 0 && startX < width && startY >= 0 && startY < height else { return image }
        
        // 새 색상 준비
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let newRed = UInt8(red * 255)
        let newGreen = UInt8(green * 255)
        let newBlue = UInt8(blue * 255)
        
        // 현재 영역 마스크가 없으면 새로 생성해야 함 (이 부분은 handleDraw에서 처리)
        guard let areaMask = currentAreaMask, isDrawing else {
            return image
        }
        
        // 작은 원 형태로 색칠 (브러시 효과)
        let brushRadius = 5 // 브러시 크기
        
        for dy in -brushRadius...brushRadius {
            for dx in -brushRadius...brushRadius {
                // 원 내부만 색칠
                if dx*dx + dy*dy > brushRadius*brushRadius {
                    continue
                }
                
                let nx = startX + dx
                let ny = startY + dy
                
                // 이미지 범위 확인
                if nx < 0 || nx >= width || ny < 0 || ny >= height {
                    continue
                }
                
                // 현재 영역 마스크 확인 - 영역 내에 있는 픽셀만 색칠
                if ny < areaMask.count && nx < areaMask[ny].count && areaMask[ny][nx] {
                    let offset = (ny * bytesPerRow) + (nx * bytesPerPixel)
                    
                    // 현재 픽셀 색상 확인 (검은색 선 위는 색칠하지 않음)
                    let currentRed = pixelData[offset]
                    let currentGreen = pixelData[offset + 1]
                    let currentBlue = pixelData[offset + 2]
                    
                    let isNotBlackLine = currentRed >= 30 || currentGreen >= 30 || currentBlue >= 30
                    
                    if isNotBlackLine {
                        // 색상 변경
                        pixelData[offset] = newRed
                        pixelData[offset + 1] = newGreen
                        pixelData[offset + 2] = newBlue
                    }
                }
            }
        }
        
        let newContext = CGContext(data: data,
                                   width: width,
                                   height: height,
                                   bitsPerComponent: bitsPerComponent,
                                   bytesPerRow: bytesPerRow,
                                   space: colorSpace,
                                   bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        guard let newCGImage = newContext.makeImage() else { return image }
        return UIImage(cgImage: newCGImage)
    }
}

// RoundedCorner 형태를 위한 extension
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ColoringView()
    }
}
