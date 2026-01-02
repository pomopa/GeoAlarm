//
//  RoundedTextField.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 2/1/26.
//

import UIKit

class RoundedTextField: UITextField {

    override func awakeFromNib() {
        super.awakeFromNib()

        layer.cornerRadius = 10
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        backgroundColor = .secondarySystemBackground

        leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        leftViewMode = .always
    }
}
