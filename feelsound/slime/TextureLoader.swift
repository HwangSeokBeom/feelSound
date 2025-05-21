//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/21/25.
//

// MARK: - TextureLoader.swift

import UIKit
import MetalKit

struct TextureLoader {
    static func loadTexture(name: String, device: MTLDevice) throws -> MTLTexture {
        guard let uiImage = UIImage(named: name)?.cgImage else {
            throw NSError(domain: "TextureLoader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Texture image not found"])
        }
        let loader = MTKTextureLoader(device: device)
        return try loader.newTexture(cgImage: uiImage, options: [
            MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.bottomLeft
        ])
    }
}
