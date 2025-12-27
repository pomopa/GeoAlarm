//
//  File.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 27/12/25.
//

import UIKit

class RegisterViewController: UIViewController {
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var repeatPsswdField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoginButton()
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

    @IBAction func registerUser(_ sender: Any) {
    }
    
}
