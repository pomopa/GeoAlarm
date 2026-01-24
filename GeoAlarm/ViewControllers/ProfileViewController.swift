//
//  ProfileViewController.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 28/12/25.
//

import UIKit
import FirebaseAuth
import FirebaseStorage

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userEmailLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
    }
    
    private func loadUserData() {
        guard let user = Auth.auth().currentUser else {
            userEmailLabel.text = NSLocalizedString("not_logged_in", comment:"")
            return
        }

        userEmailLabel.text = user.email

        if let cachedImage = ProfileImageCache.shared.load() {
            profileImageView.image = cachedImage
        }

        let storageRef = Storage.storage()
            .reference()
            .child("profile_images/\(user.uid).jpg")

        storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            guard let data = data,
                  let image = UIImage(data: data) else { return }

            DispatchQueue.main.async {
                self.profileImageView.image = image
                ProfileImageCache.shared.save(image)
            }
        }
    }
    
    //--------------------------------------------
    // IMAGE EDIT
    //--------------------------------------------
    @IBAction func editPicture(_ sender: Any) {
        let alert = UIAlertController(title: NSLocalizedString("change_profile_picture", comment: ""),message: nil,
                preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: NSLocalizedString("camera", comment: ""), style: .default) { _ in
            PermissionsHelper.checkCamera { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.openImagePicker(source: .camera)
                    } else {
                        PermissionsHelper.showSettingsAlert(
                            on: self,
                            title: NSLocalizedString("camera_access_needed", comment: ""),
                            message: NSLocalizedString("enable_camera_access", comment: "")
                        )
                    }
                }
            }
        })

        alert.addAction(UIAlertAction(title: NSLocalizedString("photo_library", comment: ""), style: .default) { _ in
            PermissionsHelper.checkPhotoLibrary { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.openImagePicker(source: .photoLibrary)
                    } else {
                        PermissionsHelper.showSettingsAlert(
                            on: self,
                            title: NSLocalizedString("library_access_needed", comment: ""),
                            message: NSLocalizedString("enable_library_access", comment: "")
                        )
                    }
                }
            }
        })

        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel))

        present(alert, animated: true)
    }
    
    private func openImagePicker(source: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(source) else { return }

        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        picker.dismiss(animated: true)

        guard let image = info[.editedImage] as? UIImage,
              let imageData = image.jpegData(compressionQuality: 0.8),
              let user = Auth.auth().currentUser else { return }

        profileImageView.image = image
        ProfileImageCache.shared.save(image)

        let storageRef = Storage.storage()
            .reference()
            .child("profile_images/\(user.uid).jpg")

        storageRef.putData(imageData) { _, error in
            if let error = error {
                print("Upload error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showAlert(title: NSLocalizedString("upload_failed", comment: ""), message: NSLocalizedString("upload_failed_text", comment: ""))
                }
                return
            }

            storageRef.downloadURL { url, _ in
                guard let url = url else { return }

                let changeRequest = user.createProfileChangeRequest()
                changeRequest.photoURL = url
                changeRequest.commitChanges(completion: nil)
            }
        }
    }


    
    //--------------------------------------------
    // Password edit
    //--------------------------------------------
    private func updatePassword(currentPassword: String, newPassword: String) {
        guard let user = Auth.auth().currentUser,
              let email = user.email else { return }

        let credential = EmailAuthProvider.credential(withEmail: email,
                                                      password: currentPassword)

        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                self.showAlert(title: "Error", message: error.localizedDescription)
                return
            }

            user.updatePassword(to: newPassword) { error in
                if let error = error {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                } else {
                    self.showAlert(title:NSLocalizedString("success", comment: ""), message: NSLocalizedString("password_updated", comment: ""))
                }
            }
        }
    }

    
    @IBAction func changePassword(_ sender: Any) {
        let alert = UIAlertController(title: NSLocalizedString("change_password", comment: ""),
                                      message: nil,
                                      preferredStyle: .alert)

        alert.addTextField { $0.placeholder = NSLocalizedString("current_password", comment: ""); $0.isSecureTextEntry = true }
        
        alert.addTextField { $0.placeholder = NSLocalizedString("new_password", comment: ""); $0.isSecureTextEntry = true }

        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("change", comment: ""), style: .default) { _ in
            let current = alert.textFields?[0].text ?? ""
            let new = alert.textFields?[1].text ?? ""
            self.updatePassword(currentPassword: current, newPassword: new)
        })

        present(alert, animated: true)
    }
    
    //--------------------------------------------
    // Delete account
    //--------------------------------------------
    private func performAccountDeletion() {
        guard let user = Auth.auth().currentUser else { return }

        let userId = user.uid

        let imageRef = Storage.storage()
            .reference()
            .child("profile_images/\(userId).jpg")

        imageRef.delete(completion: nil)

        FirestoreHelper.deleteAllAlarms { result in
            if case .failure(let error) = result {
                DispatchQueue.main.async {
                    self.showAlert(
                        title: "Error",
                        message: error.localizedDescription
                    )
                }
                return
            }

            user.delete { error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.showAlert(
                            title: "Error",
                            message: error.localizedDescription
                        )
                    }
                    return
                }

                DispatchQueue.main.async {
                    ProfileImageCache.shared.delete()
                    LocationManager.shared.removeAllGeofences()
                    self.performSegue(
                        withIdentifier: "profileToLogin",
                        sender: nil
                    )
                }
            }
        }
    }


    
    @IBAction func deleteAccount(_ sender: Any) {
        let alert = UIAlertController(title: NSLocalizedString("delete_account", comment: ""),
                                      message: NSLocalizedString("irreversible", comment: ""),
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("delete", comment: ""), style: .destructive) { _ in
            self.performAccountDeletion()
        })

        present(alert, animated: true)
    }
    
    //--------------------------------------------
    // Logout
    //--------------------------------------------
    @IBAction func logoutUser(_ sender: Any) {
        let alert = UIAlertController(
            title: NSLocalizedString("logout", comment: ""),
            message: NSLocalizedString("logout_confirmation", comment: ""),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("logout", comment: ""), style: .destructive) { _ in
            do {
                try Auth.auth().signOut()
                ProfileImageCache.shared.delete()

                DispatchQueue.main.async {
                    LocationManager.shared.removeAllGeofences()
                    self.performSegue(withIdentifier: "profileToLogin", sender: nil)
                }

            } catch {
                self.showAlert(title: "Error", message: error.localizedDescription)
            }
        })
        
        present(alert, animated: true)
    }
    
}
