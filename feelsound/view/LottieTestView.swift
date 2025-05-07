//
//  LottieTestView.swift
//  feelsound
//
//  Created by 심소영 on 5/8/25.
//

import SwiftUI
import Lottie

struct LottieTestView: UIViewRepresentable {
    let name: String
    let loopMode: LottieLoopMode
    let animationSpeed: CGFloat
    let contentMode: UIView.ContentMode
    var isPaused : Bool
    @Binding var play: Bool
    
    let animationView: LottieAnimationView
    
    init(name: String,
         loopMode: LottieLoopMode = .playOnce,
         animationSpeed: CGFloat = 1,
         contentMode: UIView.ContentMode = .scaleAspectFit,
         isPaused : Bool,
         play: Binding<Bool> = .constant(true)) {
        self.name = name
        self.animationView = LottieAnimationView(name: name)
        self.loopMode = loopMode
        self.animationSpeed = animationSpeed
        self.contentMode = contentMode
        self.isPaused = isPaused
        self._play = play
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        animationView.contentMode = contentMode
        animationView.loopMode = loopMode
        animationView.animationSpeed = animationSpeed
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)

        animationView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        animationView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
       
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if isPaused {
            context.coordinator.parent.animationView.pause()
        }else{
            context.coordinator.parent.animationView.play()
        }
        context.coordinator.parent.animationView.animationSpeed = CGFloat(animationSpeed)

//        if play {
//            animationView.play { _ in
////                play = false
//            }
//        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator : NSObject {
        
        var parent : LottieTestView
        init(_ parent : LottieTestView){
            self.parent = parent
        }
    }

}
