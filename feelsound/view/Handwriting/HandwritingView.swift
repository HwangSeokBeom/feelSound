//
//  HandwritingView.swift
//  feelsound
//
//  Created by 안준경 on 5/27/25.
//

import SwiftUI

struct HandwritingView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State Properties
    @State private var originalImage: UIImage?
    @State private var floodFillImage: UIImage?
    @State private var selectedColor: Color = .cyan
    @State private var currentAreaMask: [[Bool]]?
    @State private var previousDrawPoint: CGPoint?
    @State private var isProcessing = false
    @State private var isDrawing = false
    @State private var brushSize: CGFloat = 100
    @StateObject private var synth = PencilSoundSynth()
    @State private var currentFontSize: CGFloat = 100
    
    
    let inputText: String
    private let fixedImageSize = UIScreen.main.bounds.width
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                TopToolbar()
                ImageView()
                Spacer()
            }
            .background(.black)
        }
        .navigationBarHidden(true)
        .onAppear(perform: setupInitialState)
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func TopToolbar() -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    @ViewBuilder
    private func ImageView() -> some View {
        VStack {
            if let image = floodFillImage {
                FixedSizeImageView(
                    image: image,
                    fixedSize: fixedImageSize,
                    onDraw: handleDraw,
                    onDrawingStateChanged: handleDrawingStateChanged
                )
                .frame(width: fixedImageSize, height: UIScreen.main.bounds.height)  // 높이를 화면 전체로
                .background(Color.white)
                .clipped()
            } else {
                Color.clear
                    .frame(width: fixedImageSize, height: UIScreen.main.bounds.height)  // 높이를 화면 전체로
                    .background(Color.white)
                    .onAppear {
                        generateImage(words: inputText)
                    }
            }
        }
        .padding(.top, 40)
        .background(Color.gray)
    }
    
    // MARK: - Setup and Helpers
    private func setupInitialState() {
        synth.stop()
    }
    
    private func generateImage(words: String) {
        if let (textImage, fontSize) = createTextImageWithFontSize(text: words) {
            let imageWithBackground = HandwritingProcessor.addWhiteBackground(to: textImage)
            originalImage = imageWithBackground
            floodFillImage = imageWithBackground
            currentFontSize = fontSize
        }
    }
    
    private func createTextImageWithFontSize(text: String) -> (UIImage, CGFloat)? {
        let imageSize = CGSize(width: fixedImageSize, height: UIScreen.main.bounds.height)
        let maxFontSize: CGFloat = 300
        let minFontSize: CGFloat = 20
        let padding: CGFloat = 40
        let scale: CGFloat = 1.0
        var bestFontSize = maxFontSize
        
        // 최적 폰트 크기 찾기
        for fontSize in stride(from: maxFontSize, through: minFontSize, by: -2) {
            let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .strokeColor: UIColor.black,
                .strokeWidth: -1.0,
                .foregroundColor: UIColor.white
            ]
            let attrStr = NSAttributedString(string: text, attributes: attributes)
            let boundingRect = attrStr.boundingRect(
                with: CGSize(width: imageSize.width - padding * 2, height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
            
            let textSize = boundingRect.size
            
            if textSize.width <= imageSize.width - padding * 2 && textSize.height <= imageSize.height - padding * 2 {
                bestFontSize = fontSize
                break
            }
        }
        
        // 최종 이미지 생성 (기존 코드와 동일)
        let finalFont = UIFont.systemFont(ofSize: bestFontSize, weight: .bold)
        let finalAttributes: [NSAttributedString.Key: Any] = [
            .font: finalFont,
            .strokeColor: UIColor.black,
            .strokeWidth: -1.0,
            .foregroundColor: UIColor.white
        ]
        let finalAttrStr = NSAttributedString(string: text, attributes: finalAttributes)
        let finalTextSize = finalAttrStr.boundingRect(
            with: CGSize(width: imageSize.width - padding * 2, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: imageSize))
        
        let textRect = CGRect(
            x: (imageSize.width - finalTextSize.width) / 2,
            y: (imageSize.height - finalTextSize.height) / 2,
            width: finalTextSize.width,
            height: finalTextSize.height
        )
        
        finalAttrStr.draw(in: textRect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let finalImage = image else { return nil }
        return (finalImage, bestFontSize) // 폰트 크기도 함께 반환
    }
    
    private func handleDrawingStateChanged(_ isCurrentlyDrawing: Bool) {
        isDrawing = isCurrentlyDrawing
        
        if !isCurrentlyDrawing {
            currentAreaMask = nil
            previousDrawPoint = nil
            synth.stop()
        }
    }
    
    private func handleDraw(at location: CGPoint) {
        guard let currentImage = floodFillImage, !isProcessing else { return }
        
        // 소리 재생
        if let prevPoint = previousDrawPoint {
            let velocity = sqrt(pow(location.x - prevPoint.x, 2) + pow(location.y - prevPoint.y, 2))
            let adjustedVolume = min(max(0.1 + Float(velocity / 100), 0.05), 0.8)
            synth.setVolume(adjustedVolume)
        } else {
            synth.setVolume(0.1)
        }
        
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let coloredImage = self.processDrawing(at: location, on: currentImage)
            
            DispatchQueue.main.async {
                self.floodFillImage = coloredImage
                self.isProcessing = false
            }
        }
    }
    
    private func processDrawing(at location: CGPoint, on image: UIImage) -> UIImage {
        let uiColor = UIColor(selectedColor)
        
        // 글자 영역인지 확인 (흰색 픽셀인지 체크)
        guard let originalImage = originalImage,
              isColorableArea(at: location, in: originalImage) else {
            return image
        }
        
        if isDrawing && currentAreaMask == nil {
              let (mask, _) = HandwritingProcessor.createAreaMask(image: originalImage, at: location)
              currentAreaMask = mask
              // 실제 폰트 크기 전달
              let result = HandwritingProcessor.drawColor(image: image, at: location, with: uiColor, areaMask: mask, fontSize: currentFontSize)
              previousDrawPoint = location
              return result
          } else if let previousPoint = previousDrawPoint {
              // 실제 폰트 크기 전달
              let result = HandwritingProcessor.drawLine(
                  image: image,
                  from: previousPoint,
                  to: location,
                  with: uiColor,
                  areaMask: currentAreaMask,
                  fontSize: currentFontSize
              )
              previousDrawPoint = location
              return result
          } else {
              // 실제 폰트 크기 전달
              let result = HandwritingProcessor.drawColor(
                  image: image,
                  at: location,
                  with: uiColor,
                  areaMask: currentAreaMask,
                  fontSize: currentFontSize
              )
              previousDrawPoint = location
              return result
          }
      }
    
    private func isColorableArea(at point: CGPoint, in image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return false }
        
        let width = cgImage.width
        let height = cgImage.height
        
        let x = Int(point.x)
        let y = Int(point.y)
        
        // 범위 체크
        guard x >= 0, x < width, y >= 0, y < height else { return false }
        
        // 이미지 데이터 추출
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else { return false }
        
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let pixelOffset = (y * bytesPerRow) + (x * bytesPerPixel)
        
        let red = bytes[pixelOffset]
        let green = bytes[pixelOffset + 1]
        let blue = bytes[pixelOffset + 2]
        
        // 개선된 threshold - 더 관대한 값으로 변경하고 주변 픽셀도 체크
        let threshold: UInt8 = 150  // 200 -> 150으로 변경
        let isMainPixelColorable = red >= threshold && green >= threshold && blue >= threshold
        
        // 주변 픽셀도 체크해서 색칠 가능 영역 확장
        if !isMainPixelColorable {
            let checkRadius = 2
            for dy in -checkRadius...checkRadius {
                for dx in -checkRadius...checkRadius {
                    let checkX = x + dx
                    let checkY = y + dy
                    
                    if checkX >= 0 && checkX < width && checkY >= 0 && checkY < height {
                        let checkOffset = (checkY * bytesPerRow) + (checkX * bytesPerPixel)
                        let checkRed = bytes[checkOffset]
                        let checkGreen = bytes[checkOffset + 1]
                        let checkBlue = bytes[checkOffset + 2]
                        
                        if checkRed >= threshold && checkGreen >= threshold && checkBlue >= threshold {
                            return true
                        }
                    }
                }
            }
        }
        
        return isMainPixelColorable
    }
}

// MARK: - Fixed Size Image View
struct FixedSizeImageView: UIViewRepresentable {
    let image: UIImage
    let fixedSize: CGFloat
    let onDraw: (CGPoint) -> Void
    let onDrawingStateChanged: (Bool) -> Void
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.image = image
        imageView.contentMode = .scaleToFill
        imageView.isUserInteractionEnabled = true
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        imageView.addGestureRecognizer(panGesture)
        
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = image
        uiView.contentMode = .scaleToFill
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        let parent: FixedSizeImageView
        
        init(_ parent: FixedSizeImageView) {
            self.parent = parent
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let imageView = gesture.view as? UIImageView else { return }
            
            let location = gesture.location(in: imageView)
            
            // 개선된 좌표 변환 - scaleToFill 모드 고려
            let imageSize = parent.image.size
            let viewSize = imageView.bounds.size
            
            // scaleToFill에서 실제 이미지가 차지하는 영역 계산
            let scaleX = imageSize.width / viewSize.width
            let scaleY = imageSize.height / viewSize.height
            
            let adjustedLocation = CGPoint(
                x: max(0, min(location.x * scaleX, imageSize.width - 1)),
                y: max(0, min(location.y * scaleY, imageSize.height - 1))
            )
            
            switch gesture.state {
            case .began:
                parent.onDrawingStateChanged(true)
                parent.onDraw(adjustedLocation)
            case .changed:
                parent.onDraw(adjustedLocation)
            case .ended, .cancelled:
                parent.onDrawingStateChanged(false)
            default:
                break
            }
        }
    }
}
