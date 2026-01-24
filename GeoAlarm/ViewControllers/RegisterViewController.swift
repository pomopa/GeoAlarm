//
//  File.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 27/12/25.
//

import UIKit
import FirebaseAuth

class RegisterViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var repeatPsswdField: UITextField!
    @IBOutlet weak var passwordStrengthLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoginButton()
        setupTextFields()
        hideKeyboardWhenTappedAround()
        configureTextFields()
        
        passwordField.addTarget(
            self,
            action: #selector(passwordChanged),
            for: .editingChanged
        )
        
        passwordStrengthLabel.text = NSLocalizedString("weak_password", comment: "")
        passwordStrengthLabel.textColor = .systemRed
    }
    
    private func configureTextFields() {
        emailField.delegate = self
        passwordField.delegate = self
        repeatPsswdField.delegate = self
        emailField.returnKeyType = .next
        passwordField.returnKeyType = .next
        repeatPsswdField.returnKeyType = .done
        
        emailField.textContentType = .emailAddress
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no

        passwordField.textContentType = .newPassword
        repeatPsswdField.textContentType = .password
        
        passwordField.isSecureTextEntry = true
        passwordField.addPasswordToggle()
        repeatPsswdField.isSecureTextEntry = true
        repeatPsswdField.addPasswordToggle()

    }
    
    private func setupLoginButton() {
        let firstColor = UIColor(red: 0x1B/255, green: 0x2B/255, blue: 0x42/255, alpha: 1)
        let secondColor = UIColor(red: 0xDB/255, green: 0x65/255, blue: 0x4D/255, alpha: 1)

        let text = NSMutableAttributedString(
            string: NSLocalizedString("already_account", comment: ""),
            attributes: [
                .foregroundColor: firstColor,
                .font: UIFont.systemFont(ofSize: 15)
            ]
        )

        text.append(NSAttributedString(
            string: NSLocalizedString("login_here", comment: ""),
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

    @IBAction func registerUser(_ sender: Any) {
        guard let email = emailField.text,
                let password = passwordField.text,
                let repeatPassword = repeatPsswdField.text else {
            return
        }

        if email.isEmpty || password.isEmpty || repeatPassword.isEmpty {
            showAlert(title: "Error", message: NSLocalizedString("all_fields", comment: "")
            )
            return
        }

        if password != repeatPassword {
            showAlert(title: "Error", message: NSLocalizedString("dont_match", comment: "")
            )
            return
        }
        
        if password.count < 6 {
            showAlert(title: "Error", message: NSLocalizedString("6chars", comment: ""))
            return
        }
        
        if password.rangeOfCharacter(from: .lowercaseLetters) == nil {
            showAlert(title: "Error", message: NSLocalizedString("one_lowercase", comment: ""))
            return
        }

        if password.rangeOfCharacter(from: .uppercaseLetters) == nil {
            showAlert(title: "Error", message: NSLocalizedString("one_uppercase", comment: ""))
            return
        }

        // Firebase registration
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            
            if let error = error {
                self?.showAlert(title: NSLocalizedString("registration_failed", comment: ""),
                                message: error.localizedDescription)
                return
            }

            let alert = UIAlertController(title: NSLocalizedString("success", comment: ""),
                                          message: NSLocalizedString("account_created_succ", comment: ""),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self?.dismiss(animated: true)
            })
            self?.present(alert, animated: true)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        DispatchQueue.main.async {
            if textField == self.emailField {
                self.passwordField.becomeFirstResponder()
            } else if textField == self.passwordField {
                self.repeatPsswdField.becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }
        }
        return true
    }
    
    private func updatePasswordStrength(_ password: String) {
        var score = 0

        if password.count >= 6 { score += 1 }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }

        switch score {
        case 0...1:
            passwordStrengthLabel.text = NSLocalizedString("weak_password", comment: "")
            passwordStrengthLabel.textColor = .systemRed
        case 2...3:
            passwordStrengthLabel.text = NSLocalizedString("medium_password", comment: "")
            passwordStrengthLabel.textColor = .systemOrange
        default:
            passwordStrengthLabel.text = NSLocalizedString("strong_password", comment: "")
            passwordStrengthLabel.textColor = .systemGreen
        }
    }

    @objc private func passwordChanged() {
        updatePasswordStrength(passwordField.text ?? "")
    }
}
