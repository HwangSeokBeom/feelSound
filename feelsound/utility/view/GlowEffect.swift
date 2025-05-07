//
//  GlowEffect.swift
//  feelsound
//
//  Created by 심소영 on 5/8/25.
//

import SwiftUI

extension View{
    func glow() -> some View {
        modifier(Glow())
    }
    
    func glowing()-> some View{
        modifier(GlowEffect())
    }
}


struct Glow : ViewModifier {
    func body(content : Content) -> some View {
        ZStack{
            content.blur(radius: 15)
            content
        }
    }
}

struct GlowEffect : ViewModifier {
    @State private var throb = false
    func body(content : Content) -> some View {
        ZStack{
            content
                .blur(radius: 15)
                .animation(.easeOut(duration: 0.5).repeatForever(), value : throb)
                .onAppear{
                    throb.toggle()
                }
            
            content
        }
    }
}
