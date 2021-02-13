//
//  MyTabBarVC.swift
//  Photo Bucket
//
//  Created by Eric Tu on 2/10/21.
//

import Foundation
import UIKit

class MyTabBarVC : UITabBarController{
    let db : MyDatabase = MyFirebaseDB()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.db.startListeningForAuth { (isSignedIn) in
            if !isSignedIn {
                self.navigationController?.popViewController(animated: true)
            }
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.db.closeListeners()
    }
    
    @IBAction func pressedLogOut(_ sender: Any) {
        db.signOut()
    }
}
