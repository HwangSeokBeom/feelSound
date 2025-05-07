//
//  Font+Ext.swift
//  feelsound
//
//  Created by 심소영 on 5/8/25.
//

import SwiftUI

extension Font {
    public static func registerFonts(fontName: String) {
        registerFont(bundle: Bundle.main , fontName: fontName, fontExtension: ".otf") //change according to your ext.
    }
    public static func registerFontsTTF(fontName: String) {
        registerFont(bundle: Bundle.main , fontName: fontName, fontExtension: ".ttf") //change according to your ext.
    }
    
    fileprivate static func registerFont(bundle: Bundle, fontName: String, fontExtension: String) {

        guard let fontURL = bundle.url(forResource: fontName, withExtension: fontExtension),
              let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
              let font = CGFont(fontDataProvider) else {
            fatalError("Couldn't create font from data")
        }

        var error: Unmanaged<CFError>?

        CTFontManagerRegisterGraphicsFont(font, &error)
    }
}

extension View {
    func CustomStroke(color : Color, width : CGFloat)->some View{
        modifier(StrokeModifier(strokeSize : width, strokeColor : color))
    }
}

struct StrokeModifier : ViewModifier {
    private let id = UUID()
    var strokeSize : CGFloat = 1
    var strokeColor : Color = .blue
    
    func body(content : Content) -> some View {
        content
            .padding(strokeSize*2)
            .background(Rectangle())
            .foregroundStyle(strokeColor)
            .mask({
                outline(context : content)
            })
    }
    
    func outline(context : Content) -> some View {
        Canvas { context, size in
            context.addFilter(.alphaThreshold(min: 0.01))
            context.drawLayer { layer in
                if let text = context.resolveSymbol(id : id){
                    layer.draw(text, at : .init(x : size.width/2, y : size.height/2))
                }
                
            }
            
        } symbols : {
            context.tag(id)
                .blur(radius: strokeSize)
        }
    }
}
