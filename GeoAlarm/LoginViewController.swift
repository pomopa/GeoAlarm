//
//  ViewController.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 27/12/25.
//

import UIKit

class LoginViewController: UIViewController {
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRegisterButton()
        setupTextFields()
    }

    private func setupRegisterButton() {
        let firstColor = UIColor(red: 0x1B/255, green: 0x2B/255, blue: 0x42/255, alpha: 1)
        let secondColor = UIColor(red: 0xDB/255, green: 0x65/255, blue: 0x4D/255, alpha: 1)

        let text = NSMutableAttributedString(
            string: "Don't have an account? ",
            attributes: [
                .foregroundColor: firstColor,
                .font: UIFont.systemFont(ofSize: 15)
            ]
        )

        text.append(NSAttributedString(
            string: "Register here",
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
    }
    
}

