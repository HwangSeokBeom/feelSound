//
//  ColoringView.swift
//  feelsound
//
//  Created by 안준경 on 5/21/25.
//

import SwiftUI

struct ColoringView: View {
    @Environment(\.dismiss) private var dismiss
    
    let imageName: String?
    
    // MARK: - State Properties
    @State private var originalImage: UIImage? // 원본 이미지
    @State private var floodFillImage: UIImage?
    @State private var selectedColor: Color = .red
    @State private var showingColorPicker = false
    @State private var currentAreaMask: [[Bool]]?
    @State private var showColorPalette = false
    @State private var previousDrawPoint: CGPoint?
    @State private var isProcessing = false
    @State private var isDrawing = false
    
    // MARK: - Zoom Properties
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    // MARK: - Constants
    private let collapsedPaletteHeight: CGFloat = 80
    private let expandedPaletteHeight: CGFloat = 200
    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    
    // MARK: - Pencil Sound
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var lastDragTime = Date()
    @State private var currentVolume: Float = 0.5
    @StateObject private var synth = PencilSoundSynth()

    private let timer = Timer.publish(every: 0.001, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                TopToolbar(onDismiss: { dismiss() })
                ImageView()
                Spacer()
            }
            .background(.black)
            
            ColorPalette()
        }
        .navigationBarHidden(true)
        .onAppear(perform: setupInitialState)
        .onReceive(timer) { _ in
            if isDragging {
                let timeSinceLastMove = Date().timeIntervalSince(lastDragTime)
                if timeSinceLastMove > 0.05 {
                    // 멈췄으면 소리 줄이기 (탭 상태 유지)
                    synth.setVolume(0.01)
                }
            } else {
                // 완전히 터치 종료되면 소리 끄기
                synth.stop()
            }
        }
        .sheet(isPresented: $showingColorPicker) {
            ColorPicker("색상 선택", selection: $selectedColor)
                .padding()
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func TopToolbar(onDismiss: @escaping () -> Void) -> some View {
        HStack {
            CloseButton(action: onDismiss)
            Spacer()
            ToolButtons()
            Spacer()
            DoneButton()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    @ViewBuilder
    private func CloseButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .frame(width: 20, height: 20)
                .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private func ToolButtons() -> some View {
        HStack(spacing: 20) {
            ToolButton(icon: "arrowshape.turn.up.left.fill", text: "undo") { }
            ToolButton(icon: "arrowshape.turn.up.right.fill", text: "redo") { }
            ToolButton(icon: "pencil.line", text: "stroke") { }
        }
    }
    
    @ViewBuilder
    private func ToolButton(icon: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .frame(width: 24, height: 18)
                Text(text)
            }
            .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private func DoneButton() -> some View {
        Button("Done") { }
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)
    }
    
    @ViewBuilder
    private func ImageView() -> some View {
        let screenWidth = UIScreen.main.bounds.width
        
        VStack {
            if let image = floodFillImage ?? UIImage(named: imageName ?? "") {
                ZoomableImageView(
                    image: image,
                    onDraw: handleDraw,
                    onDrawingStateChanged: handleDrawingStateChanged,
                    scale: $scale,
                    offset: $offset
                )
                .frame(width: screenWidth, height: screenWidth)
                .background(Color.white)
                .clipped()
            } else {
                Text("이미지를 찾을 수 없습니다")
                    .foregroundColor(.red)
            }
            Spacer()
        }
        .padding(.top, 40)
        .background(Color.gray)
    }
    
    @ViewBuilder
    private func ColorPalette() -> some View {
        VStack {
            Spacer()
            
            VStack(spacing: 0) {
                PaletteToggleButton()
                
                if showColorPalette {
                    ColorGrid()
                }
            }
            .frame(height: showColorPalette ? expandedPaletteHeight : collapsedPaletteHeight)
            .background(Color.black)
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .shadow(radius: 5)
            .animation(.spring(), value: showColorPalette)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    @ViewBuilder
    private func PaletteToggleButton() -> some View {
        HStack {
            Spacer()
            Button {
                withAnimation(.spring()) {
                    showColorPalette.toggle()
                }
            } label: {
                Image(systemName: showColorPalette ? "chevron.down" : "chevron.up")
                    .frame(width: 20, height: 14)
                    .foregroundColor(.white)
            }
            .padding(.top, -20)
            Spacer()
        }
        .frame(height: 20)
    }
    
    @ViewBuilder
    private func ColorGrid() -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 0)], spacing: 10) {
            ForEach(colors, id: \.self) { color in
                ColorCircle(color: color, isSelected: color == selectedColor) {
                    selectedColor = color
                }
            }
            
            CustomColorButton {
                showingColorPicker = true
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 20)
    }
    
    @ViewBuilder
    private func ColorCircle(color: Color, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Circle()
            .fill(color)
            .frame(width: 40, height: 40)
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.black : Color.clear, lineWidth: 3)
            )
            .onTapGesture(perform: onTap)
    }
    
    @ViewBuilder
    private func CustomColorButton(onTap: @escaping () -> Void) -> some View {
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
            .onTapGesture(perform: onTap)
    }
}

// MARK: - Setup and Helpers
extension ColoringView {
    private func setupInitialState() {
        if let imageName = imageName, let image = UIImage(named: imageName) {
            let resizedImage = ImageProcessor.resizeImageIfNeeded(image, maxSize: 1000)
            let imageWithBackground = ImageProcessor.addWhiteBackground(to: resizedImage) // 흰색 배경 합성
            originalImage = imageWithBackground
            floodFillImage = imageWithBackground
        }
        
        // 오디오 초기화 - 무음으로 시작
        synth.stop()
    }
    
    private func handleDrawingStateChanged(_ isCurrentlyDrawing: Bool) {
        isDrawing = isCurrentlyDrawing
        
        if !isCurrentlyDrawing {
            currentAreaMask = nil
            previousDrawPoint = nil
            // 드로잉 종료 시 소리도 정지
            isDragging = false
            synth.stop()
        }
    }
    
    private func handleDraw(at location: CGPoint) {
        guard let currentImage = floodFillImage, !isProcessing else { return }
        
        // 소리 재생 로직 추가
        if !isDragging {
            isDragging = true
            synth.setVolume(0.1) // 초기 탭 볼륨
        }
        
        // 드래그 속도 계산
        if let prevPoint = previousDrawPoint {
            let velocity = sqrt(pow(location.x - prevPoint.x, 2) + pow(location.y - prevPoint.y, 2))
            let adjustedVolume = min(max(0.1 + Float(velocity / 100), 0.05), 0.8)
            synth.setVolume(adjustedVolume)
        }
        
        lastDragTime = Date()
        
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let coloredImage = processDrawing(at: location, on: currentImage)
            
            DispatchQueue.main.async {
                self.floodFillImage = coloredImage
                self.isProcessing = false
            }
        }
    }
    
    private func processDrawing(at location: CGPoint, on image: UIImage) -> UIImage {
        let uiColor = UIColor(selectedColor)
        
        if isDrawing && currentAreaMask == nil {
            // 원본 이미지로 영역 마스크 생성
            let (mask, _) = ImageProcessor.createAreaMask(image: originalImage ?? image, at: location)
            currentAreaMask = mask
            let result = ImageProcessor.drawColor(image: image, at: location, with: uiColor, areaMask: mask)
            previousDrawPoint = location
            return result
        } else if let previousPoint = previousDrawPoint {
            let result = ImageProcessor.drawLine(
                image: image,
                from: previousPoint,
                to: location,
                with: uiColor,
                areaMask: currentAreaMask
            )
            previousDrawPoint = location
            return result
        } else {
            let result = ImageProcessor.drawColor(
                image: image,
                at: location,
                with: uiColor,
                areaMask: currentAreaMask
            )
            previousDrawPoint = location
            return result
        }
    }
}

// MARK: - Shape Extensions
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
