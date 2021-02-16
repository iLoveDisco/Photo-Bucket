//
//  Photo.swift
//  Photo Bucket
//
//  Created by Eric Tu on 2/15/21.
//

import Foundation
import Firebase
class Photo {
    
    var caption : String
    var authorID : String
    var url : String
    var id : String
    
    
    init (_ snapshot : DocumentSnapshot) {
        self.caption = snapshot.data()!["caption"] as! String
        self.authorID = snapshot.data()!["author"] as! String
        self.url = snapshot.data()!["url"] as! String
        self.id = snapshot.documentID
    }
}
