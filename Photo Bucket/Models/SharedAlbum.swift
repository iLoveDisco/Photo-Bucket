//
//  SharedAlbum.swift
//  Photo Bucket
//
//  Created by Eric Tu on 2/13/21.
//

import Foundation
import UIKit
import Firebase

class SharedAlbum {
    var authorID : String
    var id : String
    var name : String
    
    init(authorID : String, id : String, name : String) {
        self.authorID = authorID
        self.id = id
        self.name = name
    }
    
    init(snapshot : DocumentSnapshot) {
        self.authorID = snapshot.data()!["author"] as! String
        self.id = snapshot.documentID
        self.name = snapshot.data()!["name"] as! String
    }
}
