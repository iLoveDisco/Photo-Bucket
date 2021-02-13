//
//  SignInPage.swift
//  Photo Bucket
//
//  Created by Eric Tu on 2/8/21.
//

import Foundation
import FirebaseUI
import UIKit

class SignInPageVC : UIViewController, FUIAuthDelegate{
    let authUI = FUIAuth.defaultAuthUI()
    let db : MyDatabase = MyFirebaseDB()
    
    let LOGIN_TO_SHARED_ALBUMS_ID = "LOGIN_TO_SA_ID"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set up the sign in VC
        authUI!.delegate = self
        self.authUI?.providers = [FUIGoogleAuth(), FUIEmailAuth()]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Check to see if user is signed in
        db.startListeningForAuth { (isSignedIn) in
            if isSignedIn {
                self.performSegue(withIdentifier: self.LOGIN_TO_SHARED_ALBUMS_ID, sender: self)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.db.closeListeners()
    }
    
    @IBAction func pressedGoButton(_ sender: Any) {
        self.db.closeListeners()
        self.showLoginVC()
    }
    
    func showLoginVC() {
        let authViewController = authUI?.authViewController()
        self.present(authViewController!, animated: true, completion: nil)
    }
    
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
  
        let firUser = authDataResult?.user
        
        if authDataResult!.additionalUserInfo!.isNewUser {
            let newUser : MyUser
                = MyUser(displayName: firUser!.displayName!, email: firUser!.email!, id: firUser!.uid)
            
            self.db.updateUser(user: newUser) {
                self.db.dbPrint("Created user in Firestore for \(newUser.email)")
                self.performSegue(withIdentifier: self.LOGIN_TO_SHARED_ALBUMS_ID, sender: self)
            }
        } else {
            self.performSegue(withIdentifier: self.LOGIN_TO_SHARED_ALBUMS_ID, sender: self)
        }
    }

}
