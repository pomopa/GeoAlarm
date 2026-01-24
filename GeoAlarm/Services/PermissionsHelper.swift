//
//  PermissionsHelper.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 23/1/26.
//

import AVFoundation
import Photos
import UIKit
import CoreLocation

final class PermissionsHelper: NSObject {
    private static var locationManager: CLLocationManager?
    private static let shared = PermissionsHelper()
    private var locationPermissionCompletion: ((Bool) -> Void)?
    
    // Location
    static func checkLocation(always: Bool = false, completion: @escaping (Bool) -> Void) {
        let status: CLAuthorizationStatus
        locationManager = CLLocationManager()
        locationManager?.delegate = shared
        status = locationManager!.authorizationStatus
            
        switch status {
        case .authorizedAlways:
            completion(true)
        case .authorizedWhenInUse:
            completion(always ? false : true)
        case .notDetermined:
            locationManager = CLLocationManager()
            locationManager?.delegate = shared
            if always {
                locationManager?.requestAlwaysAuthorization()
            } else {
                locationManager?.requestWhenInUseAuthorization()
            }
            shared.locationPermissionCompletion = completion
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    // Camera
    static func checkCamera(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    // Photo Library
    static func checkPhotoLibrary(completion: @escaping (Bool) -> Void) {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                completion(status == .authorized || status == .limited)
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    // Convenience Alert
    static func showSettingsAlert(on vc: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("settings", comment: ""), style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        vc.present(alert, animated: true)
    }
}

extension PermissionsHelper: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard let completion = locationPermissionCompletion else { return }
        
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            break
        @unknown default:
            completion(false)
        }
        
        locationPermissionCompletion = nil
        PermissionsHelper.locationManager = nil
    }
}
