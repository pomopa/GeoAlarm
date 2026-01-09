//
//  MaxRadiusHelper.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 9/1/26.
//

import UIKit

struct RadiusHelper {
    static let maxMeters: Double = 1000
    
    static func calculateRadiusInMeters(unit: String, value: Double) -> Double{
        switch unit {
        case "km":
            return value * 1000
        case "m":
            return value
        case "mi":
            return value * 1609.34
        case "ft":
            return value * 0.3048
        default:
            return -1
        }
    }
    
    static func maxRadius(for unit: String) -> Double {
        switch unit {
        case "km": return maxMeters / 1000
        case "m": return maxMeters
        case "mi": return maxMeters / 1609.34
        case "ft": return maxMeters / 0.3048
        default: return maxMeters / 1000
        }
    }
    
    static func maxRadiusText(for unit: String) -> String {
        switch unit {
        case "km":
            let kmValue = 1
            return "The maximum radius value is \(kmValue) km"
        case "m":
            let mValue = 1000
            return "The maximum radius value is \(mValue) m"
        case "mi":
            let miValue = 0.62
            return String(format: "The maximum radius value is \(miValue) mi")
        case "ft":
            let ftValue = 3281
            return String(format: "The maximum radius value is \(ftValue) ft")
        default:
            return "The maximum radius value is 1 km"
        }
    }
}
