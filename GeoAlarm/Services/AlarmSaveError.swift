//
//  AlarmSaveError.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 22/1/26.
//
import UIKit

enum AlarmSaveError: LocalizedError {
    case notLoggedIn
    case radiusTooLarge(max: Double, unit: String)
    case radiusTooSmall(min: Double, unit: String)

    var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return "User not logged in"

        case .radiusTooLarge(let max, let unit):
            return String(format: "The maximum allowed radius for %@ is %.2f %@", unit, max, unit)

        case .radiusTooSmall(let min, let unit):
            return String(format: "The minimum allowed radius for %@ is %.2f %@", unit, min, unit)
        }
    }
    
}
