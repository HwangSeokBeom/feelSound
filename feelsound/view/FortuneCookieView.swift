//
//  FortuneCookieView.swift
//  feelsound
//
//  Created by 심소영 on 5/8/25.
//

import SwiftUI

struct FortuneCookieView: View {
    @Environment(\.dismiss) private var dismiss

    @State var showText : Bool = false

    var body: some View {
        VStack{
            HStack{
                Button(action: {
                    dismiss()

                }, label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width:50, height:50)
                        .padding(20)
                })
                
                Spacer()
            }
                        
            WiseSaying(showText : $showText)
            
            Coloring(showText : $showText)
        }
    }
}

struct WiseSaying : View{
    @Binding var showText : Bool

    var body: some View {
        VStack{
            Text("You are good person")
                .font(.title.bold())
                .opacity(showText ? 1.0 : 0.0)
        }
    }
}

struct Coloring: View {
    @State var isPaused : Bool = false
    @State var played : Bool = false
    @State private var toggleCount: Int = 0
    let maxToggles = 3
    @Binding var showText : Bool

    var body: some View {
        VStack{
            Button(action : {
                togglePause()

            }){
                LottieTestView(name: "fortune_cookie", animationSpeed: 1, isPaused: isPaused)

            }
            .disabled(!isPaused)
        }
        .onAppear{
            isPaused = true
        }
    }
    
    func togglePause(){
        if toggleCount < maxToggles {
            isPaused = false
            SoundManager.instance.playSound(sound: .crack3, soundExtension: .mp3)

            if(toggleCount < maxToggles - 1){
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isPaused = true
                }
                
            }
            
            toggleCount += 1
            
            if(toggleCount == maxToggles){
                withAnimation{
                    showText = true
                }
            }
        }
    }
}
