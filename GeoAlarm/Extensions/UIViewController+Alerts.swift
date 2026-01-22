//
//  UIViewController+Alerts.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 8/1/26.
//

import UIKit

extension UIViewController {

    func showAlert(
        title: String,
        message: String,
        buttonTitle: String = "OK",
        onOk: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(title: buttonTitle, style: .default) { _ in
                onOk?()
            }
        )

        present(alert, animated: true)
    }
}

