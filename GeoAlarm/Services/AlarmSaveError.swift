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
            return NSLocalizedString("not_logged_in", comment: "")

        case .radiusTooLarge(let max, let unit):
            let format = NSLocalizedString("maxRadius", comment: "")

            return String(format: format, unit, max, unit)

        case .radiusTooSmall(let min, let unit):
            let format = NSLocalizedString("minRadius", comment: "")

            return String(format: format, unit, min, unit)
        }
    }
    
}
