//
//  UIViewController+Layout.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 8/1/26.
//

import UIKit

extension UIViewController {

    func updateTableViewHeight(
        rows: Int,
        rowHeight: CGFloat = 60,
        maxHeight: CGFloat = 200,
        constraint: NSLayoutConstraint,
        animationDuration: TimeInterval = 0.3
    ) {
        let calculatedHeight = CGFloat(rows) * rowHeight
        constraint.constant = min(calculatedHeight, maxHeight)

        UIView.animate(withDuration: animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
}
