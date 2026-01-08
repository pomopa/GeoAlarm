//
//  UITextField+PasswordToggle.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 8/1/26.
//

import UIKit

extension UITextField {

    func addPasswordToggle(
        tintColor: UIColor = .gray
    ) {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.tintColor = tintColor
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)

        button.addAction(
            UIAction { [weak self, weak button] _ in
                guard let self, let button else { return }

                self.isSecureTextEntry.toggle()
                let imageName = self.isSecureTextEntry ? "eye.slash" : "eye"
                button.setImage(UIImage(systemName: imageName), for: .normal)
            },
            for: .touchUpInside
        )

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 30))
        button.center = container.center
        container.addSubview(button)

        rightView = container
        rightViewMode = .always
    }
}
