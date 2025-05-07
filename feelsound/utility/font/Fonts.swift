//
//  Fonts.swift
//  feelsound
//
//  Created by 심소영 on 5/8/25.
//

import SwiftUI

/**
Example
 Text("Share my stats")
    .font(.urbRegular(size: 18))
 */
extension Font {

    static func poppins(size: Int, weight: CustomWeight) -> Font {
        Font.custom("Poppins-\(weight.rawValue)", size: Double(size))
    }
    static func micro5(size: Int) -> Font {
        Font.custom("Micro5-Regular", size: Double(size))
    }
    
    static func micro5c(size : Int) -> Font {
        Font.custom("Micro5Charted-Regular", size : Double(size))
    }
    
    static func righteous(size : Int) -> Font {
        Font.custom("Righteous-Regular", size : Double(size))
    }

    static func pretendard(size: Int, weight: CustomWeight) -> Font {
        Font.custom("Pretendard-\(weight.rawValue)", size: Double(size))
    }

//    static func openSans(size: Int, weight: CustomWeight) -> Font {
//        Font.custom("OpenSans-\(weight.rawValue)", size: Double(size))
//    }
//    static func urbRegular(size: Int) -> Font {
//        Font.custom("Urbanist-Regular", size: CGFloat(size))
//    }
//    static func urbMedium(size: Int) -> Font {
//        Font.custom("Urbanist-Medium", size: CGFloat(size))
//    }
//
//    static func fjallaOne(size: Int) -> Font {
//        Font.custom("FjallaOne-Regular", size: CGFloat(size))
//    }


    enum CustomWeight: String {
        case bold = "Bold"
        case semibold = "SemiBold"
        case medium = "Medium"
        case regular = "Regular"
        case light = "Light"
    }
}
