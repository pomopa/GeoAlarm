//
//  ProfileViewController.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 28/12/25.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userEmailLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
    }
    
    @IBAction func editPicture(_ sender: Any) {
    }
    
    @IBAction func changePassword(_ sender: Any) {
    }
    
    @IBAction func deleteAccount(_ sender: Any) {
    }
}
