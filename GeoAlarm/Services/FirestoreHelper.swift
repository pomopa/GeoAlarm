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
    //--------------------------
    // Fetch active alarm count
    //--------------------------
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
    
    //--------------------------
    // Save alarms
    //--------------------------
    static func saveOrUpdateAlarm(
        alarmID: String? = nil,
        locationName: String,
        coordinate: CLLocationCoordinate2D,
        radius: Double,
        unit: String,
        isActive: Bool? = nil, // only used for creation
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(AlarmSaveError.notLoggedIn))
            return
        }

        let radiusInMeters = RadiusHelper.calculateRadiusInMeters(unit: unit, value: radius)
        let maxRadius = RadiusHelper.maxRadius(for: unit)
        let minRadius = RadiusHelper.minRadius(for: unit)

        guard radiusInMeters <= 1000 else {
            completion(.failure(AlarmSaveError.radiusTooLarge(max: maxRadius, unit: unit)))
            return
        }

        guard radiusInMeters >= 100 else {
            completion(.failure(AlarmSaveError.radiusTooSmall(min: minRadius, unit: unit)))
            return
        }

        let db = Firestore.firestore()
        let docRef: DocumentReference
        var data: [String: Any] = [
            "locationName": locationName,
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "radius": radius,
            "unit": unit
        ]
        
        if let alarmID = alarmID {
            // Editing existing alarm
            docRef = db.collection("users").document(userId)
                        .collection("alarms").document(alarmID)
        } else {
            // Creating new alarm
            docRef = db.collection("users").document(userId)
                        .collection("alarms").document()
            data["createdAt"] = Timestamp(date: Date())
            data["isActive"] = isActive ?? false
        }

        let action: (DocumentReference, [String: Any], ((Error?) -> Void)?) -> Void =
            alarmID == nil ? { $0.setData($1, completion: $2) } : { $0.updateData($1, completion: $2) }

        action(docRef, data) { error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if alarmID == nil, isActive == true {
                LocationManager.shared.addGeofence(
                    id: docRef.documentID,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    radius: radiusInMeters
                )
            }

            completion(.success(docRef.documentID))
        }
    }
    
    //--------------------------
    // Delete ALL alarms
    //--------------------------
    static func deleteAllAlarms(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.success(()))
            return
        }

        let db = Firestore.firestore()
        let alarmsRef = db
            .collection("users")
            .document(userId)
            .collection("alarms")

        alarmsRef.getDocuments { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let documents = snapshot?.documents, !documents.isEmpty else {
                completion(.success(()))
                return
            }

            let batch = db.batch()
            
            documents.forEach { document in
                batch.deleteDocument(document.reference)
            }
            
            batch.commit { error in
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
        
    //--------------------------
    // Get all alarms
    //--------------------------
    @discardableResult
    static func listenToAlarms(
        orderedByCreationDate: Bool = false,
        completion: @escaping (Result<[Alarm], Error>) -> Void
    ) -> ListenerRegistration? {

        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.success([]))
            return nil
        }

        var query: Query = Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("alarms")

        if orderedByCreationDate {
            query = query.order(
                by: "createdAt",
                descending: true
            )
        }

        return query.addSnapshotListener { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }

            let alarms = snapshot?.documents.compactMap {
                Alarm(id: $0.documentID, data: $0.data())
            } ?? []

            completion(.success(alarms))
        }
    }
    
    //--------------------------
    // Update alarms state
    //--------------------------
    static func updateAlarmActiveState(
        alarmID: String,
        isActive: Bool,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError()))
            return
        }

        Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("alarms")
            .document(alarmID)
            .updateData(["isActive": isActive])

        completion(.success(()))
    }
    
}
