//
//  AlarmTableViewCell.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 30/12/25.
//

import UIKit

class AlarmTableViewCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var enabledSwitch: UISwitch!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        selectionStyle = .none

        containerView.layer.cornerRadius = 20
        containerView.clipsToBounds = false	

        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.12
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 6

        enabledSwitch.onTintColor = .systemGreen
    }
    
    func configure(title: String, distance: String, isEnabled: Bool) {
        titleLabel.text = title
        distanceLabel.text = distance
        enabledSwitch.isOn = isEnabled

        updateEnabledState(isEnabled)
    }
    
    private func updateEnabledState(_ enabled: Bool) {
        let alpha: CGFloat = enabled ? 1.0 : 0.6
        titleLabel.alpha = alpha
        distanceLabel.alpha = alpha
    }
    
}
