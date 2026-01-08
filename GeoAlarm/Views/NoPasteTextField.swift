//
//  NoPasteTextField.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 2/1/26.
//

import UIKit

class NoPasteTextField: UITextField {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(paste(_:)) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
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
