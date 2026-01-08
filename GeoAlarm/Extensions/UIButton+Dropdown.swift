//
//  UIButton+Dropdown.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 8/1/26.
//

import UIKit

extension UIButton {

    func configureDropdown(
        title: String = "Units",
        options: [String],
        selectionHandler: ((String) -> Void)? = nil
    ) {
        let actions = options.map { option in
            UIAction(title: option) { _ in
                self.setTitle(option, for: .normal)
                selectionHandler?(option)
            }
        }

        self.menu = UIMenu(title: title, children: actions)
        self.showsMenuAsPrimaryAction = true
    }
}
