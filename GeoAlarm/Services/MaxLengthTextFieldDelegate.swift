//
//  MaxLengthTextFieldDelegate.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 22/1/26.
//

import UIKit

final class MaxLengthTextFieldDelegate: NSObject, UITextFieldDelegate {
    
    private let maxLength: Int
    
    init(maxLength: Int) {
        self.maxLength = maxLength
        super.init()
    }
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        return updatedText.count <= maxLength
    }
}
