//
//  ProfilePageVC.swift
//  Photo Bucket
//
//  Created by Eric Tu on 2/12/21.
//

import Foundation
import UIKit

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}

extension ProfilePageVC : ImagePickerDelegate {
    func didSelect(image: UIImage?) {
        self.profilePicView.image = image
    }
}

class ProfilePageVC : UIViewController {
    
    var imagePicker : ImagePickerVC!
    let db : MyDatabase = MyFirebaseDB()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialize the image picker
        self.imagePicker = ImagePickerVC(presentationController: self, delegate: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        self.db.listenForUser(uid: self.db.getCurrentUser().id) { (user) in
            self.profilePicView.load(url: URL(string: user.photoURL)!)
            self.displayNameTF.text = user.displayName
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.db.closeListeners()
    }
    
    @IBOutlet weak var profilePicView: UIImageView!

    @IBAction func pressedUpload(_ sender: UIButton) {
        self.imagePicker.present(from: sender)
    }
    
    @IBOutlet weak var displayNameTF: UITextField!
    
    @IBAction func pressedUpdate(_ sender: Any) {
        self.db.uploadPic(type: "profile-pics", img: self.profilePicView.image!) { (url) in
            self.db.updateUser(user: MyUser(displayName: self.displayNameTF.text!,
                                            email: self.db.getCurrentUser().email,
                                            id: self.db.getCurrentUser().id, photoURL: url)) {
                self.db.dbPrint("User has been successfully updated")
            }
        }
    }
}
