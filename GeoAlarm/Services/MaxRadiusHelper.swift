//
//  MaxRadiusHelper.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 9/1/26.
//

import UIKit

struct RadiusHelper {
    static let maxMeters: Double = 1000
    static let minMeters: Double = 100
    
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
    
    static func minRadius(for unit: String) -> Double {
        switch unit {
        case "km": return minMeters / 1000
        case "m": return minMeters
        case "mi": return minMeters / 1609.34
        case "ft": return minMeters / 0.3048
        default: return minMeters / 1000
        }
    }
    
    static func radiusText(for unit: String) -> String {
        let maxValue = maxRadius(for: unit)
        let minValue = minRadius(for: unit)

        let minStr: String
        let maxStr: String

        switch unit {
        case "km", "mi":
            minStr = String(format: "%.2f", minValue)
            maxStr = String(format: "%.2f", maxValue)
        case "m", "ft":
            minStr = String(format: "%.0f", minValue)
            maxStr = String(format: "%.0f", maxValue)
        default:
            return  NSLocalizedString("current_temperature", comment: "")
        }

        let format = NSLocalizedString("radius_range_error", comment: "")
        return String(format: format, minStr, maxStr, unit)
    }


}
