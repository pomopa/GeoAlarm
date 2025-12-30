//
//  SearchViewController.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 30/12/25.
//

import UIKit

class SearchViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var radiusTextField: UITextField!
    @IBOutlet weak var unitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureDropdownButtons()
    }
    
    func configureDropdownButtons() {
        let units = ["km", "m", "mi", "ft"]

        let actions = units.map { unit in
            UIAction(title: unit) { _ in
                self.unitButton.setTitle(unit, for: .normal)
            }
        }

        unitButton.menu = UIMenu(title: "Units", children: actions)
        unitButton.showsMenuAsPrimaryAction = true
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        let location = searchBar.text ?? ""
        let radius = radiusTextField.text ?? ""
        let unit = unitButton.title(for: .normal) ?? ""

        print("Location: \(location), Radius: \(radius) \(unit)")
    }
    
}
