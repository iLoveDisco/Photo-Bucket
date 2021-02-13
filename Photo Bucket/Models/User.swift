//
//  User.swift
//  Photo Bucket
//
//  Created by Eric Tu on 2/8/21.
//

import Foundation
import Firebase
class MyUser {
    var displayName : String
    var email : String
    var id : String
    var photoURL : String
    
    let DEFAULT_PHOTO_URL = "https://firebasestorage.googleapis.com/v0/b/photobucket-20f92.appspot.com/o/profile-pics%2Fbaseline_account_box_black_36pt_1x.png?alt=media&token=c3220850-43dc-4231-ae5c-90ed69b933ef"
    
    init(displayName : String, email : String, id : String) {
        self.displayName = displayName
        self.email = email
        self.id = id
        self.photoURL = DEFAULT_PHOTO_URL
    }
    
    init(displayName : String, email : String, id : String, photoURL : String) {
        self.displayName = displayName
        self.email = email
        self.id = id
        self.photoURL = photoURL
    }
    
}
