//
//  ProfileViewController.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 28/12/25.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {
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
    }
    
    @IBAction func editPicture(_ sender: Any) {
    }
    
    private func showSimpleAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
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
    
    @IBAction func deleteAccount(_ sender: Any) {
    }
}
