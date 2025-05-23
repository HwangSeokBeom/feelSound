//
//  ColoringView.swift
//  feelsound
//
//  Created by 안준경 on 5/21/25.
//

import SwiftUI

struct ColoringView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State Properties
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
    
    let imageName: String?
    
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
        if let imageName = imageName, let originalImage = UIImage(named: imageName) {
            floodFillImage = ImageProcessor.resizeImageIfNeeded(originalImage, maxSize: 1000)
        }
    }
    
    private func handleDrawingStateChanged(_ isCurrentlyDrawing: Bool) {
        isDrawing = isCurrentlyDrawing
        
        if !isCurrentlyDrawing {
            currentAreaMask = nil
            previousDrawPoint = nil
        }
    }
    
    private func handleDraw(at location: CGPoint) {
        guard let currentImage = floodFillImage, !isProcessing else { return }
        
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
            let (mask, processedImage) = ImageProcessor.createAreaMask(image: image, at: location)
            currentAreaMask = mask
            let result = ImageProcessor.drawColor(image: processedImage, at: location, with: uiColor, areaMask: mask)
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

// MARK: - Image Processing
struct ImageProcessor {
    static func resizeImageIfNeeded(_ image: UIImage, maxSize: CGFloat = 1000) -> UIImage {
        let size = image.size
        let maxDimension = max(size.width, size.height)
        
        guard maxDimension > maxSize else { return image }
        
        let scale = maxSize / maxDimension
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
    
    static func createAreaMask(image: UIImage, at point: CGPoint) -> ([[Bool]], UIImage) {
        guard let cgImage = image.cgImage else { return ([], image) }
        let width = cgImage.width
        let height = cgImage.height
        
        var mask = Array(repeating: Array(repeating: false, count: width), count: height)
        
        let context = createImageContext(width: width, height: height)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data else { return (mask, image) }
        let pixelData = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        
        let startX = Int(point.x)
        let startY = Int(point.y)
        
        guard isValidPoint(x: startX, y: startY, width: width, height: height) else {
            return (mask, image)
        }
        
        let startColor = getPixelColor(pixelData: pixelData, x: startX, y: startY, width: width)
        
        guard !isBlackLine(startColor) else { return (mask, image) }
        
        floodFill(mask: &mask, pixelData: pixelData, startX: startX, startY: startY,
                  startColor: startColor, width: width, height: height)
        
        return (mask, image)
    }
    
    static func drawColor(image: UIImage, at point: CGPoint, with color: UIColor, areaMask: [[Bool]]?) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let width = cgImage.width
        let height = cgImage.height
        
        let context = createImageContext(width: width, height: height)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data else { return image }
        let pixelData = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        
        let colorComponents = getColorComponents(color)
        let brushRadius = calculateBrushRadius(imageSize: CGSize(width: CGFloat(width), height: CGFloat(height)))
        
        drawBrush(pixelData: pixelData, center: point, color: colorComponents,
                  brushRadius: brushRadius, areaMask: areaMask, width: width, height: height)
        
        return createImageFromContext(context) ?? image
    }
    
    static func drawLine(image: UIImage, from startPoint: CGPoint, to endPoint: CGPoint,
                        with color: UIColor, areaMask: [[Bool]]?) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let width = cgImage.width
        let height = cgImage.height
        
        let context = createImageContext(width: width, height: height)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data else { return image }
        let pixelData = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        
        let colorComponents = getColorComponents(color)
        let brushRadius = calculateBrushRadius(imageSize: CGSize(width: CGFloat(width), height: CGFloat(height)))
        
        drawBresenhamLine(pixelData: pixelData, from: startPoint, to: endPoint,
                         color: colorComponents, brushRadius: brushRadius,
                         areaMask: areaMask, width: width, height: height)
        
        return createImageFromContext(context) ?? image
    }
}

// MARK: - Image Processing Helpers
extension ImageProcessor {
    private static func createImageContext(width: Int, height: Int) -> CGContext {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        return CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                        bytesPerRow: 4 * width, space: colorSpace,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    }
    
    private static func isValidPoint(x: Int, y: Int, width: Int, height: Int) -> Bool {
        return x >= 0 && x < width && y >= 0 && y < height
    }
    
    private static func getPixelColor(pixelData: UnsafeMutablePointer<UInt8>, x: Int, y: Int, width: Int) -> (UInt8, UInt8, UInt8) {
        let offset = (y * width * 4) + (x * 4)
        return (pixelData[offset], pixelData[offset + 1], pixelData[offset + 2])
    }
    
    private static func isBlackLine(_ color: (UInt8, UInt8, UInt8)) -> Bool {
        return color.0 < 30 && color.1 < 30 && color.2 < 30
    }
    
    private static func getColorComponents(_ color: UIColor) -> (UInt8, UInt8, UInt8) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (UInt8(red * 255), UInt8(green * 255), UInt8(blue * 255))
    }
    
    private static func calculateBrushRadius(imageSize: CGSize) -> Int {
        let maxDimension = max(imageSize.width, imageSize.height)
        return max(6, Int(maxDimension / 120))
    }
    
    private static func createImageFromContext(_ context: CGContext) -> UIImage? {
        guard let cgImage = context.makeImage() else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    private static func floodFill(mask: inout [[Bool]], pixelData: UnsafeMutablePointer<UInt8>,
                                 startX: Int, startY: Int, startColor: (UInt8, UInt8, UInt8),
                                 width: Int, height: Int) {
        var stack = [(startX, startY)]
        var visited = Array(repeating: Array(repeating: false, count: width), count: height)
        
        while !stack.isEmpty {
            let (x, y) = stack.removeLast()
            
            guard isValidPoint(x: x, y: y, width: width, height: height) && !visited[y][x] else { continue }
            
            visited[y][x] = true
            
            let currentColor = getPixelColor(pixelData: pixelData, x: x, y: y, width: width)
            let isSimilar = abs(Int(currentColor.0) - Int(startColor.0)) < 20 &&
                           abs(Int(currentColor.1) - Int(startColor.1)) < 20 &&
                           abs(Int(currentColor.2) - Int(startColor.2)) < 20
            
            if isSimilar && !isBlackLine(currentColor) {
                mask[y][x] = true
                
                stack.append((x+1, y))
                stack.append((x-1, y))
                stack.append((x, y+1))
                stack.append((x, y-1))
            }
        }
    }
    
    private static func drawBrush(pixelData: UnsafeMutablePointer<UInt8>, center: CGPoint,
                                 color: (UInt8, UInt8, UInt8), brushRadius: Int,
                                 areaMask: [[Bool]]?, width: Int, height: Int) {
        let startX = Int(center.x)
        let startY = Int(center.y)
        
        for dy in -brushRadius...brushRadius {
            for dx in -brushRadius...brushRadius {
                guard dx*dx + dy*dy <= brushRadius*brushRadius else { continue }
                
                let nx = startX + dx
                let ny = startY + dy
                
                guard isValidPoint(x: nx, y: ny, width: width, height: height) else { continue }
                
                if let mask = areaMask {
                    guard ny < mask.count && nx < mask[ny].count && mask[ny][nx] else { continue }
                }
                
                let offset = (ny * width * 4) + (nx * 4)
                let currentColor = (pixelData[offset], pixelData[offset + 1], pixelData[offset + 2])
                
                if !isBlackLine(currentColor) {
                    pixelData[offset] = color.0
                    pixelData[offset + 1] = color.1
                    pixelData[offset + 2] = color.2
                }
            }
        }
    }
    
    private static func drawBresenhamLine(pixelData: UnsafeMutablePointer<UInt8>, from startPoint: CGPoint,
                                         to endPoint: CGPoint, color: (UInt8, UInt8, UInt8),
                                         brushRadius: Int, areaMask: [[Bool]]?, width: Int, height: Int) {
        let dx = abs(Int(endPoint.x) - Int(startPoint.x))
        let dy = abs(Int(endPoint.y) - Int(startPoint.y))
        let sx = Int(startPoint.x) < Int(endPoint.x) ? 1 : -1
        let sy = Int(startPoint.y) < Int(endPoint.y) ? 1 : -1
        var err = dx - dy
        
        var x = Int(startPoint.x)
        var y = Int(startPoint.y)
        
        while true {
            drawBrush(pixelData: pixelData, center: CGPoint(x: x, y: y), color: color,
                     brushRadius: brushRadius, areaMask: areaMask, width: width, height: height)
            
            if x == Int(endPoint.x) && y == Int(endPoint.y) { break }
            
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
    }
}

// MARK: - ZoomableImageView
struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    let onDraw: (CGPoint) -> Void
    let onDrawingStateChanged: (Bool) -> Void
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        let imageView = UIImageView(image: image)
        
        setupScrollView(scrollView, context: context)
        setupImageView(imageView, context: context)
        setupConstraints(scrollView: scrollView, imageView: imageView)
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        if let imageView = uiView.subviews.first as? UIImageView {
            imageView.image = image
        }
        uiView.zoomScale = scale
        uiView.contentOffset = CGPoint(x: offset.width, y: offset.height)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func setupScrollView(_ scrollView: UIScrollView, context: Context) {
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.zoomScale = scale
        scrollView.contentOffset = CGPoint(x: offset.width, y: offset.height)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
    }
    
    private func setupImageView(_ imageView: UIImageView, context: Context) {
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.delegate = context.coordinator
        imageView.addGestureRecognizer(panGesture)
    }
    
    private func setupConstraints(scrollView: UIScrollView, imageView: UIImageView) {
        scrollView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }
}

// MARK: - Coordinator
extension ZoomableImageView {
    class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        var parent: ZoomableImageView
        var lastPoint: CGPoint?
        
        init(_ parent: ZoomableImageView) {
            self.parent = parent
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.subviews.first
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            parent.scale = scrollView.zoomScale
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            parent.offset = CGSize(width: scrollView.contentOffset.x, height: scrollView.contentOffset.y)
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return false
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let imageView = gesture.view as? UIImageView,
                  let image = imageView.image else { return }
            
            let location = gesture.location(in: imageView)
            
            guard let pixelPoint = convertToPixelCoordinates(location: location, imageView: imageView, image: image)
            else { return }
            
            handleGestureState(gesture.state, at: pixelPoint)
        }
        
        private func convertToPixelCoordinates(location: CGPoint, imageView: UIImageView, image: UIImage) -> CGPoint? {
            let viewSize = imageView.bounds.size
            let imageSize = image.size
            
            let imageAspect = imageSize.width / imageSize.height
            let viewAspect = viewSize.width / viewSize.height
            
            let (displayedImageSize, imageOrigin) = calculateImageFrame(viewSize: viewSize, imageAspect: imageAspect, viewAspect: viewAspect)
            let imageFrame = CGRect(origin: imageOrigin, size: displayedImageSize)
            
            guard imageFrame.contains(location) else { return nil }
            
            let normalizedX = (location.x - imageFrame.origin.x) / imageFrame.width
            let normalizedY = (location.y - imageFrame.origin.y) / imageFrame.height
            
            return CGPoint(x: normalizedX * imageSize.width, y: normalizedY * imageSize.height)
        }
        
        private func calculateImageFrame(viewSize: CGSize, imageAspect: CGFloat, viewAspect: CGFloat) -> (CGSize, CGPoint) {
            if imageAspect > viewAspect {
                let size = CGSize(width: viewSize.width, height: viewSize.width / imageAspect)
                let origin = CGPoint(x: 0, y: (viewSize.height - size.height) / 2)
                return (size, origin)
            } else {
                let size = CGSize(width: viewSize.height * imageAspect, height: viewSize.height)
                let origin = CGPoint(x: (viewSize.width - size.width) / 2, y: 0)
                return (size, origin)
            }
        }
        
        private func handleGestureState(_ state: UIGestureRecognizer.State, at point: CGPoint) {
            switch state {
            case .began:
                parent.onDrawingStateChanged(true)
                lastPoint = point
                parent.onDraw(point)
            case .changed:
                if let lastPoint = lastPoint {
                    interpolatePoints(from: lastPoint, to: point)
                }
                lastPoint = point
            case .ended, .cancelled:
                parent.onDrawingStateChanged(false)
                lastPoint = nil
            default:
                break
            }
        }
        
        private func interpolatePoints(from startPoint: CGPoint, to endPoint: CGPoint) {
            let distance = hypot(endPoint.x - startPoint.x, endPoint.y - startPoint.y)
            let numberOfPoints = max(Int(distance), 10)
            
            guard numberOfPoints >= 2 else {
                parent.onDraw(endPoint)
                return
            }
            
            for i in 1...numberOfPoints {
                let ratio = CGFloat(i) / CGFloat(numberOfPoints)
                let x = startPoint.x + (endPoint.x - startPoint.x) * ratio
                let y = startPoint.y + (endPoint.y - startPoint.y) * ratio
                parent.onDraw(CGPoint(x: x, y: y))
            }
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

struct ColoringView_Previews: PreviewProvider {
    static var previews: some View {
        ColoringView(imageName: "panda1")
    }
}
