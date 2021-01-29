//
//  MyDatabase.swift
//  Photo Bucket
//
//  Created by Eric Tu on 1/25/21.
//

import Foundation
import Firebase

protocol MyDatabase {
    // PhotoBucket-related queries
    
    // Bare necessities
    func create(_ doc : NSDictionary)
    func read(order : String, descending : Bool, limit : Int, constructor: @escaping (Any) -> Any )
    func update(docName : String, doc : NSDictionary)
    func delete(docName : String)
    func close()
}

class MyFirebaseDB : MyDatabase {
    var ref : CollectionReference!
    var listener : ListenerRegistration!
    var data : [Any]
    
    init(_ collectionName : String) {
        ref = Firestore.firestore().collection(collectionName)
        listener = nil
        data = [Any]()
    }

    func create(_ doc: NSDictionary) {
        ref.addDocument(data: doc as! [String: Any])
    }
    
    func read(order : String,
              descending : Bool = true,
              limit : Int = 50,
              constructor: @escaping (Any) -> Any) {
        
        listener = ref.order(by: order, descending: true).limit(to: limit).addSnapshotListener({ (query, error) in
            if let query = query {
                self.data.removeAll()
                query.documents.forEach({(doc) in
                    self.data.append(constructor(doc))
                })
            }
        })
    }
    
    func update(docName: String, doc: NSDictionary) {
        ref.document(docName).updateData(doc as! [AnyHashable : Any])
    }
    
    func delete(docName: String) {
        ref.document(docName).delete()
    }
    
    func close() {
        listener.remove()
    }
}
