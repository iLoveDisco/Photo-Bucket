//
//  PhotobucketTableViewController.swift
//  Photo Bucket
//
//  Created by Eric Tu on 1/28/21.
//

import UIKit

class PhotoBucketTableViewController : UITableViewController{

    override func viewDidLoad() {
        print("here")
        let myDB = MyFirebaseDB("photos")
        myDB.delete(docName: "jd5oUbj2COTNcUIuVCsZ")
        
    }
}
