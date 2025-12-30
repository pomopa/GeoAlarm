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
            userEmailLabel.text = "Not logged in"
            return
        }

        userEmailLabel.text = user.email
        
        let storageRef = Storage.storage().reference().child("profile_images/\(user.uid).jpg")

        storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            if let error = error {
                print("Error downloading the profile picture:", error)
                return
            }

            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImageView.image = image
                }
            }
        }
    }
    
    private func showSimpleAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    //--------------------------------------------
    // IMAGE EDIT
    //--------------------------------------------
    @IBAction func editPicture(_ sender: Any) {
        let alert = UIAlertController(title: "Change Profile Picture",
                                      message: nil,
                                      preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
            self.openImagePicker(source: .camera)
        })

        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
            self.openImagePicker(source: .photoLibrary)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

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

        let storageRef = Storage.storage().reference()
            .child("profile_images/\(user.uid).jpg")

        storageRef.putData(imageData) { _, error in
            if let error = error {
                print("Upload failed:", error)
                return
            }

            storageRef.downloadURL { url, _ in
                guard let url = url else { return }

                let changeRequest = user.createProfileChangeRequest()
                changeRequest.photoURL = url
                changeRequest.commitChanges { _ in
                    DispatchQueue.main.async {
                        self.profileImageView.image = image
                    }
                }
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
                self.showSimpleAlert("Error", error.localizedDescription)
                return
            }

            user.updatePassword(to: newPassword) { error in
                if let error = error {
                    self.showSimpleAlert("Error", error.localizedDescription)
                } else {
                    self.showSimpleAlert("Success", "Password updated")
                }
            }
        }
    }

    
    @IBAction func changePassword(_ sender: Any) {
        let alert = UIAlertController(title: "Change Password",
                                      message: nil,
                                      preferredStyle: .alert)

        alert.addTextField { $0.placeholder = "Current password"; $0.isSecureTextEntry = true }
        alert.addTextField { $0.placeholder = "New password"; $0.isSecureTextEntry = true }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Change", style: .default) { _ in
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

        let imageRef = Storage.storage().reference()
            .child("profile_images/\(user.uid).jpg")

        imageRef.delete(completion: nil)

        user.delete { error in
            if let error = error {
                self.showSimpleAlert("Error", error.localizedDescription)
                return
            }

            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "profileToLogin", sender: nil)
            }
        }
    }

    
    @IBAction func deleteAccount(_ sender: Any) {
        let alert = UIAlertController(title: "Delete Account",
                                      message: "This action is permanent",
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.performAccountDeletion()
        })

        present(alert, animated: true)
    }
    
    //--------------------------------------------
    // Logout
    //--------------------------------------------
    @IBAction func logoutUser(_ sender: Any) {
        let alert = UIAlertController(
            title: "Log out",
            message: "Are you sure you want to log out?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Log out", style: .destructive) { _ in
            do {
                try Auth.auth().signOut()

                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "profileToLogin", sender: nil)
                }

            } catch {
                self.showSimpleAlert("Error", error.localizedDescription)
            }
        })
        
        present(alert, animated: true)
    }
    
}
