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
}
