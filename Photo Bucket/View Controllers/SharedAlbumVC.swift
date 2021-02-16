//
//  PhotoTableVC.swift
//  Photo Bucket
//
//  Created by Eric Tu on 2/12/21.
//

import UIKit

extension SharedAlbumVC : ImagePickerDelegate {
    
    func didSelect(image: UIImage?) {
        // TODO : Handle image selection
        if let image = image {
            db.uploadPic(type: "photos", img: image) { (url) in
                
                self.db.createPhoto(sharedAlbumID: self.selectedAlbum.id, caption: self.imgCaption, url: url)
            }
        }
    }
}

class SharedAlbumVC : UITableViewController{
    var selectedAlbum : SharedAlbum!
    let db : MyDatabase = MyFirebaseDB()
    
    private var addBtn : UIButton!
    private var delBtn : UIButton!
    private var imgCaption : String!
    private var photos : [Photo] = [Photo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        if let album = selectedAlbum {
            
            if let foundView = self.navigationController?.view.viewWithTag(123) {
                addBtn = (foundView as! UIButton)
                addBtn.addTarget(self, action: #selector(self.pressedAddPhoto), for: .touchUpInside)
            }
            
            if let foundView = self.navigationController?.view.viewWithTag(1234) {
                delBtn = (foundView as! UIButton)
                delBtn.addTarget(self, action: #selector(self.pressedDeletePhoto), for: .touchUpInside)
            }
            
            db.listenForPhotos(sharedAlbumID: album.id) { (photos) in
                self.photos.removeAll()
                for photo in photos {
                    self.photos.append(photo)
                }
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        addBtn.removeTarget(self, action: #selector(self.pressedAddPhoto), for: .touchUpInside)
        delBtn.removeTarget(self, action: #selector(self.pressedDeletePhoto), for: .touchUpInside)
    }
    
    @objc func pressedAddPhoto() {
        self.performSegue(withIdentifier: "UPLOAD_PIC_SEGUE_ID", sender: self)
    }
    
    @objc func pressedDeletePhoto() {
        self.setEditing(!self.isEditing, animated: true)
        
        if self.tableView.isEditing {
            delBtn.setImage(UIImage(systemName: "trash.fill"), for: .normal)
        } else {
            delBtn.setImage(UIImage(systemName: "trash"), for: .normal)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.photos.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PHOTO_CELL_ID", for: indexPath)
        
        // Configure the cell
        cell.textLabel?.text = photos[indexPath.row].caption
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return photos[indexPath.row].authorID == db.getCurrentUser().id || selectedAlbum.authorID == db.getCurrentUser().id
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            db.deletePhoto(sharedAlbumID: selectedAlbum.id, photoID: self.photos[indexPath.row].id)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "UPLOAD_PIC_SEGUE_ID" {
            (segue.destination as! PhotoUploadPageVC).album = self.selectedAlbum
        }
    }
}
