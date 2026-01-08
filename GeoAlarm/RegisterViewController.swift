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
        
        passwordStrengthLabel.text = "Weak password"
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
        passwordField.isSecureTextEntry = true

        repeatPsswdField.textContentType = .password
        repeatPsswdField.isSecureTextEntry = true
        
        addPasswordToggle(to: passwordField)
        addPasswordToggle(to: repeatPsswdField)
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

            let alert = UIAlertController(title: "Success",
                                          message: "Account created successfully",
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
    
    private func addPasswordToggle(to textField: UITextField) {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.tintColor = .gray
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)

        button.addAction(UIAction { _ in
            textField.isSecureTextEntry.toggle()
            let imageName = textField.isSecureTextEntry ? "eye.slash" : "eye"
            button.setImage(UIImage(systemName: imageName), for: .normal)
        }, for: .touchUpInside)

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 30))
        button.center = container.center
        container.addSubview(button)
        
        textField.rightView = container
        textField.rightViewMode = .always
    }
    
    private func updatePasswordStrength(_ password: String) {
        var score = 0

        if password.count >= 6 { score += 1 }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }

        switch score {
        case 0...1:
            passwordStrengthLabel.text = "Weak password"
            passwordStrengthLabel.textColor = .systemRed
        case 2...3:
            passwordStrengthLabel.text = "Medium password"
            passwordStrengthLabel.textColor = .systemOrange
        default:
            passwordStrengthLabel.text = "Strong password"
            passwordStrengthLabel.textColor = .systemGreen
        }
    }

    @objc private func passwordChanged() {
        updatePasswordStrength(passwordField.text ?? "")
    }
}
