//
//  Alarm.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 31/12/25.
//

import FirebaseFirestore

struct Alarm {
    let id: String
    let locationName: String
    let latitude: Double
    let longitude: Double
    let radius: Double
    let unit: String
    var isActive: Bool
    let createdAt: Timestamp
    let creationType: AlarmCreationType

    init?(id: String, data: [String: Any]) {
        guard
            let locationName = data["locationName"] as? String,
            let latitude = data["latitude"] as? Double,
            let longitude = data["longitude"] as? Double,
            let radius = data["radius"] as? Double,
            let unit = data["unit"] as? String,
            let isActive = data["isActive"] as? Bool,
            let createdAt = data["createdAt"] as? Timestamp,
            let creationTypeString = data["creationType"] as? String,
            let creationType = AlarmCreationType(rawValue: creationTypeString)
        else {
            return nil
        }

        self.id = id
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.unit = unit
        self.isActive = isActive
        self.createdAt = createdAt
        self.creationType = creationType
    }
}
