//
//  MTKView.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/14/25.
//

import MetalKit

class SlimeMTKView: MTKView {
    var renderer: SlimeRenderer?

    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        self.isMultipleTouchEnabled = true // ✅ 멀티터치 허용!
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        renderer?.handleTouches(touches, in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        renderer?.handleTouches(touches, in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let id = ObjectIdentifier(touch)
            renderer?.touchStartTimes.removeValue(forKey: id)
            renderer?.touchInputs.removeAll { $0.id == id }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            renderer?.touchStartTimes.removeValue(forKey: ObjectIdentifier(touch))
        }
        renderer?.touchInputs.removeAll()
    }
}
