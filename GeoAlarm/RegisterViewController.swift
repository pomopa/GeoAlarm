//
//  File.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 27/12/25.
//

import UIKit
import FirebaseAuth

class RegisterViewController: UIViewController {
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var repeatPsswdField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoginButton()
        setupTextFields()
        hideKeyboardWhenTappedAround()
    }
    
    private func setupLoginButton() {
        let firstColor = UIColor(red: 0x1B/255, green: 0x2B/255, blue: 0x42/255, alpha: 1)
        let secondColor = UIColor(red: 0xDB/255, green: 0x65/255, blue: 0x4D/255, alpha: 1)

        let text = NSMutableAttributedString(
            string: "Already have an account? ",
            attributes: [
                .foregroundColor: firstColor,
                .font: UIFont.systemFont(ofSize: 15)
            ]
        )

        text.append(NSAttributedString(
            string: "Login here",
            attributes: [
                .foregroundColor: secondColor,
                .font: UIFont.boldSystemFont(ofSize: 15)
            ]
        ))

        loginButton.setAttributedTitle(text, for: .normal)
    }
    
    private func setupTextFields() {
        let textColor = UIColor(red: 0x1B/255, green: 0x2B/255, blue: 0x42/255, alpha: 1)

        emailField.textColor = textColor
        passwordField.textColor = textColor
        repeatPsswdField.textColor = textColor
    }
    
    private func showAlert(title: String, message: String,
                           completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }


    @IBAction func registerUser(_ sender: Any) {
        guard let email = emailField.text,
                let password = passwordField.text,
                let repeatPassword = repeatPsswdField.text else {
            return
        }

        if email.isEmpty || password.isEmpty || repeatPassword.isEmpty {
            showAlert(title: "Error", message: "All fields are required")
            return
        }

        if password != repeatPassword {
            showAlert(title: "Error", message: "Passwords do not match")
            return
        }
        
        if password.count < 6 {
            showAlert(title: "Error", message: "Password must be at least 6 characters")
            return
        }
        
        if password.rangeOfCharacter(from: .lowercaseLetters) == nil {
            showAlert(title: "Error", message: "Password must contain at least one lowercase letter")
            return
        }

        if password.rangeOfCharacter(from: .uppercaseLetters) == nil {
            showAlert(title: "Error", message: "Password must contain at least one uppercase letter")
            return
        }

        // Firebase registration
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            
            if let error = error {
                self?.showAlert(title: "Registration failed",
                                message: error.localizedDescription)
                return
            }

            self?.showAlert(title: "Success",
                            message: "Account created successfully") {
                self?.dismiss(animated: true)
            }
        }
    }
    
}
