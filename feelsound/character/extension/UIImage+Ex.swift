//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/23/25.
//

import CoreML
import UIKit

extension UIImage {
    func resize(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        draw(in: CGRect(origin: .zero, size: size))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }

    func toCVPixelBuffer() -> CVPixelBuffer? {
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary

        var buffer: CVPixelBuffer?
        let width = Int(self.size.width)
        let height = Int(self.size.height)

        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width, height,
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &buffer)

        guard let result = buffer, status == kCVReturnSuccess else {
            return nil
        }

        CVPixelBufferLockBaseAddress(result, [])

        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(result),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(result),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )

        if let cgImage = self.cgImage {
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        CVPixelBufferUnlockBaseAddress(result, [])

        return result
    }
}
