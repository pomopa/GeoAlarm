//
//  UILabel+NLines.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 9/1/26.
//
import UIKit

extension UILabel {
    var numberOfTextLines: Int {
        guard let text = text, let font = font else { return 0 }

        let maxSize = CGSize(width: frame.width, height: CGFloat.greatestFiniteMagnitude)
        let textHeight = text.boundingRect(
            with: maxSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).height

        let lineHeight = font.lineHeight
        return Int(round(textHeight / lineHeight))
    }
}
