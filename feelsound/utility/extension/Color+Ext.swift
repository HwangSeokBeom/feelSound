//
//  Color+Ext.swift
//  feelsound
//
//  Created by 심소영 on 5/8/25.
//

import SwiftUI

extension Color{
    
    static let secondaryGray: Color = Color("secondaryGray")
    static let primaryBg: Color = Color("BG")
    static let lightGray: Color = Color("lightGray")
    static let secondaryGray2: Color = Color("secondaryGray2")
    static let background = Color("color-black")
    static let grayColor = Color("color-darkgray")
    static let purpleColor = Color("running")
    static let EBF2FF = Color("EBF2FF")
    static let backgroundColor = Color("1E1D2A")
    static let boxColor = Color("2C2E3F")
    static let bluePurple = Color(hex: "5265DB")
    static let color1 = Color(hex: "#8978F8")
    static let color2 = Color(hex: "#8850F8")
    static let color3 = Color(hex: "#A350F8")
    static let color4 = Color(hex: "#C054F8")
}

extension Color {
    init(hex: String) {
        self.init(UIColor(hex: hex))
    }

    var uiColor: UIColor { .init(self) }
    typealias RGBA = (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)
    var rgba: RGBA? {
        var (r, g, b, a): RGBA = (0, 0, 0, 0)
        return uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) ? (r, g, b, a) : nil
    }

    var hexRGBA: String {
        guard let rgba = rgba else { return "#ffffffff" }
        return String(format: "#%02x%02x%02x%02x",
                      Int(rgba.red * 255),
                      Int(rgba.green * 255),
                      Int(rgba.blue * 255),
                      Int(rgba.alpha * 255))
    }
    
    static var random: Color {
        return Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1))
    }
}

extension UIColor {
    convenience init(hex: String) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 1

        let hexColor = hex.replacingOccurrences(of: "#", with: "").lowercased()
        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0
        var valid = false
        
        if scanner.scanHexInt64(&hexNumber) {
            if hexColor.count == 8 {
                r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                a = CGFloat(hexNumber & 0x000000ff) / 255
                valid = true
            }
            else if hexColor.count == 6 {
                r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                b = CGFloat(hexNumber & 0x0000ff) / 255
                valid = true
            }
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

