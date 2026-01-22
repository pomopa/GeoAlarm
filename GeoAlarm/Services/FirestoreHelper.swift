//
//  FirestoreHelper.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 22/1/26.
//

import FirebaseAuth
import FirebaseFirestore

final class FirestoreHelper {
    
    static func fetchActiveAlarmCount(
            completion: @escaping (Int) -> Void
        ) {
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
    
}
