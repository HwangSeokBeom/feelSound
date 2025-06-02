//
//  HandwritingProcessor.swift
//  feelsound
//
//  Created by 안준경 on 5/29/25.
//

import SwiftUI

// MARK: - Image Processing
struct HandwritingProcessor {
    static func resizeImageIfNeeded(_ image: UIImage, maxSize: CGFloat = 1000) -> UIImage {
        let size = image.size
        let maxDimension = max(size.width, size.height)
        
        guard maxDimension > maxSize else { return image }
        
        let scale = maxSize / maxDimension
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)//1.0)
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
        
        // 더 정확한 flood fill 알고리즘 사용
        improvedFloodFill(mask: &mask, pixelData: pixelData, startX: startX, startY: startY,
                  startColor: startColor, width: width, height: height)
        
        return (mask, image)
    }
    
    private static func improvedFloodFill(mask: inout [[Bool]], pixelData: UnsafeMutablePointer<UInt8>,
                                         startX: Int, startY: Int, startColor: (UInt8, UInt8, UInt8),
                                         width: Int, height: Int) {
        var stack = [(startX, startY)]
        var visited = Array(repeating: Array(repeating: false, count: width), count: height)
        
        let tolerance: Int = 25 // 15 -> 25로 증가하여 더 관대하게 영역 인식
        
        while !stack.isEmpty {
            let (x, y) = stack.removeLast()
            
            guard isValidPoint(x: x, y: y, width: width, height: height) && !visited[y][x] else { continue }
            
            visited[y][x] = true
            
            let currentColor = getPixelColor(pixelData: pixelData, x: x, y: y, width: width)
            
            guard !isBlackLine(currentColor) else { continue }
            
            let isSimilarToStart = abs(Int(currentColor.0) - Int(startColor.0)) < tolerance &&
                                  abs(Int(currentColor.1) - Int(startColor.1)) < tolerance &&
                                  abs(Int(currentColor.2) - Int(startColor.2)) < tolerance
            
            let isStartColored = !isWhiteOrSimilar(startColor)
            let isCurrentColored = !isWhiteOrSimilar(currentColor)
            
            let shouldInclude = isSimilarToStart || (isStartColored && isCurrentColored)
            
            if shouldInclude {
                mask[y][x] = true
                
                // 8방향으로 확장 (대각선 포함)
                let directions = [(1,0), (-1,0), (0,1), (0,-1), (1,1), (1,-1), (-1,1), (-1,-1)]
                for (dx, dy) in directions {
                    stack.append((x+dx, y+dy))
                }
            }
        }
    }
    
    static func drawColor(image: UIImage, at point: CGPoint, with color: UIColor, areaMask: [[Bool]]?, fontSize: CGFloat) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let width = cgImage.width
        let height = cgImage.height
        
        let context = createImageContext(width: width, height: height)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data else { return image }
        let pixelData = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        
        let colorComponents = getColorComponents(color)
        let brushRadius = calculateBrushRadius(fontSize: fontSize) // 폰트 크기 기반 브러시
        
        // 자동 색칠 체크
        if let mask = areaMask {
            let fillPercentage = checkFillPercentage(pixelData: pixelData, areaMask: mask, width: width, height: height)
            if fillPercentage >= 0.7 {
                // 70% 이상이면 파란색으로 자동 색칠
                let blueComponents = getColorComponents(UIColor.blue)
                fillAreaWithColor(pixelData: pixelData, areaMask: mask, color: blueComponents, width: width, height: height)
                return createImageFromContext(context) ?? image
            }
        }
        
        drawBrush(pixelData: pixelData, center: point, color: colorComponents,
                  brushRadius: brushRadius, areaMask: areaMask, width: width, height: height)
        
        return createImageFromContext(context) ?? image
    }
    
    private static func checkFillPercentage(pixelData: UnsafeMutablePointer<UInt8>, areaMask: [[Bool]], width: Int, height: Int) -> Double {
        var totalPixels = 0
        var coloredPixels = 0
        
        for y in 0..<height {
            for x in 0..<width {
                if y < areaMask.count && x < areaMask[y].count && areaMask[y][x] {
                    totalPixels += 1
                    let offset = (y * width * 4) + (x * 4)
                    let color = (pixelData[offset], pixelData[offset + 1], pixelData[offset + 2])
                    
                    // 흰색이 아니면 색칠된 것으로 간주
                    if !isWhiteOrSimilar(color) && !isBlackLine(color) {
                        coloredPixels += 1
                    }
                }
            }
        }
        
        return totalPixels > 0 ? Double(coloredPixels) / Double(totalPixels) : 0.0
    }
    
    static func drawLine(image: UIImage, from startPoint: CGPoint, to endPoint: CGPoint,
                        with color: UIColor, areaMask: [[Bool]]?, fontSize: CGFloat) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let width = cgImage.width
        let height = cgImage.height
        
        let context = createImageContext(width: width, height: height)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data else { return image }
        let pixelData = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        
        let colorComponents = getColorComponents(color)
        let brushRadius = calculateBrushRadius(fontSize: fontSize) // 폰트 크기 기반 브러시
        
        // 자동 색칠 체크
        if let mask = areaMask {
            let fillPercentage = checkFillPercentage(pixelData: pixelData, areaMask: mask, width: width, height: height)
            if fillPercentage >= 0.7 {
                // 70% 이상이면 파란색으로 자동 색칠
                let blueComponents = getColorComponents(UIColor.blue)
                fillAreaWithColor(pixelData: pixelData, areaMask: mask, color: blueComponents, width: width, height: height)
                return createImageFromContext(context) ?? image
            }
        }
        
        drawBresenhamLine(pixelData: pixelData, from: startPoint, to: endPoint,
                         color: colorComponents, brushRadius: brushRadius,
                         areaMask: areaMask, width: width, height: height)
        
        return createImageFromContext(context) ?? image
    }
    
    private static func fillAreaWithColor(pixelData: UnsafeMutablePointer<UInt8>, areaMask: [[Bool]], color: (UInt8, UInt8, UInt8), width: Int, height: Int) {
        for y in 0..<height {
            for x in 0..<width {
                if y < areaMask.count && x < areaMask[y].count && areaMask[y][x] {
                    let offset = (y * width * 4) + (x * 4)
                    let currentColor = (pixelData[offset], pixelData[offset + 1], pixelData[offset + 2])
                    
                    // 검은 줄이 아닌 경우에만 색칠
                    if !isBlackLine(currentColor) {
                        pixelData[offset] = color.0
                        pixelData[offset + 1] = color.1
                        pixelData[offset + 2] = color.2
                    }
                }
            }
        }
    }
}

// MARK: - Image Processing Helpers
extension HandwritingProcessor {
    private static func createImageContext(width: Int, height: Int) -> CGContext {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        return CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                        bytesPerRow: 4 * width, space: colorSpace,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    }
    
    // 투명 배경일 때 영역 인식용 흰색 배경 합성
    static func addWhiteBackground(to image: UIImage) -> UIImage {
        let size = image.size
        let rect = CGRect(origin: .zero, size: size)
        
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        // 흰색 배경 그리기
        UIColor.white.setFill()
        UIRectFill(rect)
        
        // 원본 이미지 그리기
        image.draw(in: rect)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
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
    
    private static func calculateBrushRadius(fontSize: CGFloat) -> Int {
        // 폰트 크기에 비례하여 브러시 크기 계산
        let baseRadius = max(3, Int(fontSize / 25))
        return min(baseRadius, 15) // 최대값 제한
    }
    
    private static func createImageFromContext(_ context: CGContext, scale: CGFloat = 1.0) -> UIImage? {//) -> UIImage? {
        guard let cgImage = context.makeImage() else { return nil }
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up) // 🟢 scale 정보 추가)
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
            
            guard !isBlackLine(currentColor) else { continue }
            
            let isSimilarToStart = abs(Int(currentColor.0) - Int(startColor.0)) < 20 &&
                                  abs(Int(currentColor.1) - Int(startColor.1)) < 20 &&
                                  abs(Int(currentColor.2) - Int(startColor.2)) < 20
            
            // 시작점이 이미 색칠된 영역인 경우, 비슷한 색칠된 영역들도 포함
            let isStartColored = !isWhiteOrSimilar(startColor)
            let isCurrentColored = !isWhiteOrSimilar(currentColor)
            
            let shouldInclude = isSimilarToStart || (isStartColored && isCurrentColored)
            
            if shouldInclude {
                mask[y][x] = true
                
                stack.append((x+1, y))
                stack.append((x-1, y))
                stack.append((x, y+1))
                stack.append((x, y-1))
            }
        }
    }
    
    // 추가 헬퍼 함수
    private static func isWhiteOrSimilar(_ color: (UInt8, UInt8, UInt8)) -> Bool {
        return color.0 > 200 && color.1 > 200 && color.2 > 200
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
