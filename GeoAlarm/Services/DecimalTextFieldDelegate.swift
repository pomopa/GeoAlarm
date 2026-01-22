//
//  DecimalTextFieldDelegate.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 21/1/26.
//

import UIKit

class DecimalTextFieldDelegate: NSObject, UITextFieldDelegate {
    private let maxDecimals: Int
    
    init(maxDecimals: Int) {
        self.maxDecimals = maxDecimals
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
            
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
            
        if updatedText.isEmpty { return true }
            
        let decimalSeparator = Locale.current.decimalSeparator ?? "."
        let numberParts = updatedText.components(separatedBy: decimalSeparator)
        if numberParts.count > 2 {
            return false
        }
            
        if numberParts.count == 2 {
            let fraction = numberParts[1]
            return fraction.count <= maxDecimals
        }
            
        return true
    }
}
