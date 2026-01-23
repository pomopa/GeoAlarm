//
//  ViewController.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 27/12/25.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRegisterButton()
        setupTextFields()
        hideKeyboardWhenTappedAround()
        
        emailField.delegate = self
        passwordField.delegate = self
        emailField.returnKeyType = .next
        passwordField.returnKeyType = .done
        
        passwordField.isSecureTextEntry = true
        passwordField.addPasswordToggle()

    }

    private func setupRegisterButton() {
        let firstColor = UIColor(red: 0x1B/255, green: 0x2B/255, blue: 0x42/255, alpha: 1)
        let secondColor = UIColor(red: 0xDB/255, green: 0x65/255, blue: 0x4D/255, alpha: 1)

        let text = NSMutableAttributedString(
            string: NSLocalizedString("no_account", comment: ""),
            attributes: [
                .foregroundColor: firstColor,
                .font: UIFont.systemFont(ofSize: 15)
            ]
        )

        text.append(NSAttributedString(
            string: NSLocalizedString("register_here", comment: ""),
            attributes: [
                .foregroundColor: secondColor,
                .font: UIFont.boldSystemFont(ofSize: 15)
            ]
        ))

        registerButton.setAttributedTitle(text, for: .normal)
    }
    
    private func setupTextFields() {
        let textColor = UIColor(red: 0x1B/255, green: 0x2B/255, blue: 0x42/255, alpha: 1)

        emailField.textColor = textColor
        passwordField.textColor = textColor
    }
    
    @IBAction func loginUser(_ sender: Any) {
        guard let email = emailField.text, !email.isEmpty,
                  let password = passwordField.text, !password.isEmpty else {
            showAlert(title: "Error", message: NSLocalizedString("email_and_password", comment: ""))
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                self.showAlert(title: NSLocalizedString("login_failed", comment: ""), message: error.localizedDescription)
                return
            }

            guard let user = result?.user else {
                self.showAlert(title: NSLocalizedString("login_failed", comment: ""), message: NSLocalizedString("user_not_found", comment: "")
                )
                return
            }

            print("User logged in:", user.uid)
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "loginToMain", sender: nil)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}

