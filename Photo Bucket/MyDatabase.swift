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
    func createPhoto(sharedAlbumID : String, caption : String, url : String)
    func updatePhoto(sharedAlbumID : String, photoID : String, caption: String)
    func deletePhoto(sharedAlbumID : String, photoID : String)
    func listenForPhotos(sharedAlbumID : String, onComplete : @escaping ([Photo]) -> Void)
    
    func createSharedAlbum(albumName : String, memberEmails : [String])
    func deleteSharedAlbum(albumID : String)
    func uploadPic(type: String, img : UIImage, onComplete : @escaping (String) -> Void)
    
    func updateUser(user : MyUser, onComplete : @escaping () -> Void)
    func getCurrentUser() -> MyUser
    func listenForUser(uid : String, onComplete : @escaping (MyUser) -> Void)
    func listenForSharedAlbums(uid : String, onComplete : @escaping ([SharedAlbum]) -> Void)
    
    func startListeningForAuth(onComplete : @escaping (_ isSignedIn : Bool) -> Void)
    func signOut()
    
    func dbPrint(_ msg : String)
    func closeListeners()
}

class MyFirebaseDB : MyDatabase {
    
    init() {
        
        Firestore.firestore().clearPersistence()
    }
    
    let storageRef = Storage.storage().reference()
    
    func uploadPic(type: String, img: UIImage, onComplete: @escaping (String) -> Void) {
        guard let d: Data = img.jpegData(compressionQuality: 0.5) else {return}
        
        let md = StorageMetadata()
        md.contentType = "image/png"
        
        let ref = storageRef.child("\(type)/\(self.getCurrentUser().id).jpg")
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
    let sharedAlbumsRef = Firestore.firestore().collection("shared albums")
    var listeners = [ListenerRegistration]()
    
    func updateUser(user : MyUser, onComplete : @escaping () -> Void) {
        usersRef.document(user.id).setData(["display name" : user.displayName,
                                            "email" : user.email,
                                            "photo url" : user.photoURL,
                                            "shared albums" : []]) { (err) in
            self.handleErrorAndSuccess(err, "Problem with storing \(user.email) in Firestore") {
                onComplete()
            }
        }
    }
    
    func listenForUser(uid : String, onComplete : @escaping (MyUser) -> Void) {
        let listener = usersRef.document(uid).addSnapshotListener { (snapshot, err) in
            self.handleErrorAndSuccess(err, "Issue with retrieving user information for \(uid)") {
                
                let user : MyUser = MyUser(snapshot!)
                onComplete(user)

            }
        }
        self.listeners.append(listener)
    }
    
    func listenForSharedAlbums(uid : String, onComplete : @escaping ([SharedAlbum]) -> Void) {
        let listener = sharedAlbumsRef.whereField("members", arrayContains: uid).addSnapshotListener { (snapshot, err) in
            self.handleErrorAndSuccess(err, "Problem retrieving shared albums for \(uid)") {
                var usersAlbums = [SharedAlbum]()
                
                if let albumDocs = snapshot?.documents {
                    
                    for doc in albumDocs {
                        usersAlbums.append(SharedAlbum(snapshot: doc))

                    }
                }
                onComplete(usersAlbums)
            }
        }
        self.listeners.append(listener)
    }
    
    func createPhoto(sharedAlbumID : String, caption : String, url : String) {
        sharedAlbumsRef.document(sharedAlbumID).collection("photos").addDocument(data: ["caption" : caption, "author" : self.getCurrentUser().id, "url" : url])
    }
    
    func updatePhoto(sharedAlbumID : String, photoID : String, caption: String) {
        sharedAlbumsRef.document(sharedAlbumID).collection("photos").document(photoID).setData(["caption":caption], merge: true)
    }
    
    func deletePhoto(sharedAlbumID : String, photoID : String) {
        sharedAlbumsRef.document(sharedAlbumID).collection("photos").document(photoID).delete()
    }
    
    func listenForPhotos(sharedAlbumID : String, onComplete : @escaping ([Photo]) -> Void) {
        sharedAlbumsRef.document(sharedAlbumID).collection("photos").addSnapshotListener { (snapshot, err) in
            self.handleErrorAndSuccess(err, "Problem with retrieving photos") {
                var photos = [Photo]()
                if let photoDocs = snapshot?.documents {
                    for doc in photoDocs {
                        photos.append(Photo(doc))
                    }
                }
                onComplete(photos)
            }
        }
    }
    
    func createSharedAlbum(albumName : String, memberEmails : [String]) {
        let sharedAlbumRef : DocumentReference = self.sharedAlbumsRef.addDocument(data: ["author" : self.getCurrentUser().id,
                                                                                         "name" : albumName,
                                                                                         "members" : []])
        // add the author as a member
        usersRef.whereField("email", in: memberEmails).getDocuments { (snapshot, err) in

            if let userDocs = snapshot?.documents {
                
                var memberIDs = [String]()
                
                for doc in userDocs {
                    if var userAlbumIDs = doc.data()["shared albums"] as? [String]{
                        userAlbumIDs.append(sharedAlbumRef.documentID)
                        self.usersRef.document(doc.documentID).setData(["shared albums" : userAlbumIDs], merge: true)
                    }
                    
                    memberIDs.append(doc.documentID)
                }
                
                sharedAlbumRef.setData(["members" : memberIDs], merge: true)
            }
        }
    }
    
    func deleteSharedAlbum(albumID : String) {
        sharedAlbumsRef.document(albumID).getDocument { (snapshot, err) in
            if let members = snapshot!.data()!["members"] as? [String] {
                
                // remove the album ID from each of the members
                for memberID in members {
                    
                    // read the member to delete an album from
                    self.usersRef.document(memberID).getDocument { (snapshot, err) in
                        
                        // look at their list of albums and delete the right one
                        if let sharedAlbumIDs = snapshot!.data()!["shared albums"] as? [String] {
                            let newAlbums = sharedAlbumIDs.filter {$0 != albumID}
                            self.usersRef.document(memberID).setData(["shared albums" : newAlbums], merge: true)
                        }
                    }
                }
            }
            
            self.sharedAlbumsRef.document(albumID).delete()
        }
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
