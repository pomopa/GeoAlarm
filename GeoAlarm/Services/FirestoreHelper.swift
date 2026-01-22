//
//  FirestoreHelper.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 22/1/26.
//

import FirebaseAuth
import FirebaseFirestore
import CoreLocation

final class FirestoreHelper {
    
    static func fetchActiveAlarmCount( completion: @escaping (Int) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(0)
            return
        }

        Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("alarms")
            .whereField("isActive", isEqualTo: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Failed to fetch alarms:", error.localizedDescription)
                    completion(0)
                    return
                }

                completion(snapshot?.documents.count ?? 0)
            }
    }
    
    static func saveAlarm(
        locationName: String,
        coordinate: CLLocationCoordinate2D,
        radius: Double,
        unit: String,
        isActive: Bool,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(AlarmSaveError.notLoggedIn))
            return
        }

        let radiusInMeters = RadiusHelper.calculateRadiusInMeters(
            unit: unit,
            value: radius
        )

        let maxRadius = RadiusHelper.maxRadius(for: unit)
        guard radiusInMeters <= 1000 else {
            completion(.failure(
                AlarmSaveError.radiusTooLarge(max: maxRadius, unit: unit)
            ))
            return
        }

        let minRadius = RadiusHelper.minRadius(for: unit)
        guard radiusInMeters >= 100 else {
            completion(.failure(
                AlarmSaveError.radiusTooSmall(min: minRadius, unit: unit)
            ))
            return
        }

        let db = Firestore.firestore()
        
        let alarmRef = db
            .collection("users")
            .document(userId)
            .collection("alarms")
            .document()

        let alarmID = alarmRef.documentID
        
        let alarmData: [String: Any] = [
            "locationName": locationName,
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "radius": radius,
            "unit": unit,
            "isActive": isActive,
            "createdAt": Timestamp(date: Date())
        ]

        alarmRef.setData(alarmData) { error in
            if let error {
                completion(.failure(error))
                return
            }

            if isActive {
                LocationManager.shared.addGeofence(
                    id: alarmID,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    radius: radiusInMeters
                )
            }

            completion(.success(alarmID))
        }
    }
    
}
