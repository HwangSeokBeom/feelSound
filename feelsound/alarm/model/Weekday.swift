//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/22/25.
//

// Weekday.swift
import Foundation

enum Weekday: String, CaseIterable, Identifiable, Codable {
    case mon, tue, wed, thu, fri, sat, sun

    var id: String { self.rawValue }

    var label: String {
        switch self {
        case .mon: return "M"
        case .tue: return "T"
        case .wed: return "W"
        case .thu: return "T"
        case .fri: return "F"
        case .sat: return "S"
        case .sun: return "S"
        }
    }

    var calendarWeekday: Int {
        switch self {
        case .sun: return 1
        case .mon: return 2
        case .tue: return 3
        case .wed: return 4
        case .thu: return 5
        case .fri: return 6
        case .sat: return 7
        }
    }
}
