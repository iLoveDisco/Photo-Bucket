//
//  MyDatabase.swift
//  Photo Bucket
//
//  Created by Eric Tu on 1/25/21.
//

import Foundation
import Firebase
import FirebaseStorage

protocol MyDatabase {
    func uploadImage(img : UIImage, onComplete : @escaping (String) -> Void)
    
    func updateUser(user : MyUser, onComplete : @escaping () -> Void)
    func getCurrentUser() -> MyUser
    func listenForUser(uid : String, onComplete : @escaping (MyUser) -> Void)
    
    func startListeningForAuth(onComplete : @escaping (_ isSignedIn : Bool) -> Void)
    func signOut()
    
    func dbPrint(_ msg : String)
    func closeListeners()
}

class MyFirebaseDB : MyDatabase {
    
    let storageRef = Storage.storage().reference()
    func uploadImage(img: UIImage, onComplete: @escaping (String) -> Void) {
        guard let d: Data = img.jpegData(compressionQuality: 0.5) else {return}
        
        let md = StorageMetadata()
        md.contentType = "image/png"
        
        let ref = storageRef.child("profile-pics/\(self.getCurrentUser().id).jpg")
        ref.putData(d, metadata: md) { (metadata, err) in
            self.handleErrorAndSuccess(err, "Problem with uploading image to server") {
                ref.downloadURL { (url, err) in
                    self.handleErrorAndSuccess(err, "Problem with handling the download URL") {
                        print("[LOG] Successfully uploaded to Firestore via \(String(describing: url))")
                        onComplete(String(describing: url!))
                    }
                }
            }
        }
    }
    
    let usersRef = Firestore.firestore().collection("users")
    var listeners = [ListenerRegistration]()
    
    
    
    func updateUser(user : MyUser, onComplete : @escaping () -> Void) {
        usersRef.document(user.id).setData(["display name" : user.displayName,
                                            "email" : user.email,
                                            "photo url" : user.photoURL]) { (err) in
            self.handleErrorAndSuccess(err, "Problem with storing \(user.email) in Firestore") {
                onComplete()
            }
        }
    }
    
    func listenForUser(uid : String, onComplete : @escaping (MyUser) -> Void) {
        let listener = usersRef.document(uid).addSnapshotListener { (snapshot, err) in
            self.handleErrorAndSuccess(err, "Issue with retrieving profile photo for user \(uid)") {
                let user : MyUser = MyUser(displayName: snapshot!.data()!["display name"] as! String,
                                           email: snapshot!.data()!["email"] as! String,
                                           id: snapshot!.documentID,
                                           photoURL: snapshot!.data()!["photo url"] as! String)
                
                onComplete(user)
            }
        }
        self.listeners.append(listener)
    }
    
    func getCurrentUser() -> MyUser {
        return MyUser(displayName: Auth.auth().currentUser!.displayName!, email: Auth.auth().currentUser!.email!, id: Auth.auth().currentUser!.uid)
    }
    
    var authStateChangeListener : AuthStateDidChangeListenerHandle!
    func startListeningForAuth(onComplete : @escaping (_ isSignedIn : Bool) -> Void) {
        authStateChangeListener = Auth.auth().addStateDidChangeListener({ (auth, user) in
            onComplete(Auth.auth().currentUser != nil)
        })
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            self.dbPrint("Sign out error")
        }
    }
    
    func handleErrorAndSuccess(_ err : Error?, _ errMessage : String, ifSuccess : () -> Void) {
        if let err = err {
            print("[FIREBASE ERROR] \(errMessage) : \n\(err)")
        } else {
            ifSuccess()
        }
    }
    
    func closeListeners() {
        if authStateChangeListener != nil {
            Auth.auth().removeStateDidChangeListener(authStateChangeListener)
        }
        
        for list in listeners {
            list.remove()
        }
    }
    
    func dbPrint(_ msg : String) {
        print("[FIREBASE] \(msg)")
    }
    
}
