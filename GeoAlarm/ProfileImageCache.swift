//
//  ProfileImageCache.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 4/1/26.
//

import FirebaseAuth
import FirebaseStorage
import UIKit

final class ProfileImageCache {

    static let shared = ProfileImageCache()
    private init() {}

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("profile_image.jpg")
    }

    func load() -> UIImage? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    func save(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func delete() {
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func prefetchIfNeeded() {
        guard let user = Auth.auth().currentUser else { return }

        if ProfileImageCache.shared.load() != nil {
            return
        }
        
        let storageRef = Storage.storage()
            .reference()
            .child("profile_images/\(user.uid).jpg")
        
        storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            guard let data = data,
                    let image = UIImage(data: data) else {
                return
            }
             
            ProfileImageCache.shared.save(image)
        }
    }
}
