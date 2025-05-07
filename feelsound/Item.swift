//
//  Item.swift
//  feelsound
//
//  Created by 심소영 on 5/8/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
