//
//  PhotobucketTableViewController.swift
//  Photo Bucket
//
//  Created by Eric Tu on 1/28/21.
//

import UIKit

class PhotoBucketTableViewController : UITableViewController{
    let db : MyDatabase = MyFirebaseDB()
    var user : MyUser!
    var albums : [SharedAlbum] = [SharedAlbum]()
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @objc func pressedAddAlbum() {
        let alertController = UIAlertController(title: "Create a new Album", message: "", preferredStyle: .alert)
        
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { (action) in
            let albumNameTF = alertController.textFields![0]
            
            var albumMembersTF = alertController.textFields![1].text!.components(separatedBy: ",")
            albumMembersTF.append(self.db.getCurrentUser().email) // Don't forget about the author
            
            self.db.createSharedAlbum(albumName: albumNameTF.text!, memberEmails: albumMembersTF)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(cancelAction)
        alertController.addAction(submitAction)
        
        alertController.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Album Name"
        })
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Member emails (comma separated)"
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func pressedDeleteAlbum() {
        if let foundView = self.navigationController?.view.viewWithTag(1234) {
            let btn = (foundView as! UIButton)
            
            self.setEditing(!self.isEditing, animated: true)
            
            if self.tableView.isEditing {
                btn.setImage(UIImage(systemName: "trash.fill"), for: .normal)
            } else {
                btn.setImage(UIImage(systemName: "trash"), for: .normal)
            }
        }
    }
    
    private func drawButton(icon : String, pos : CGPoint) -> UIButton{
        let button = UIButton(frame : CGRect(origin: pos, size : CGSize(width: 60, height: 60)))
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.backgroundColor = UIColor.white
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.setImage(UIImage(systemName: icon), for: .normal)
        return button
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.db.listenForSharedAlbums(uid: self.db.getCurrentUser().id) { (albums) in
            self.albums.removeAll()
            
            albums.forEach { (album) in
                self.albums.append(album)
            }
            
            self.tableView.reloadData()
        }
        
        let addAlbumButton = self.drawButton(icon: "plus",
                        pos: CGPoint(x: self.view.frame.width / 2 + 80, y:self.view.frame.size.height - 190))
        addAlbumButton.addTarget(self, action: #selector(self.pressedAddAlbum), for: .touchUpInside)
        addAlbumButton.tag = 123
        self.navigationController?.view.addSubview(addAlbumButton)
        
        let deleteAlbumButton = self.drawButton(icon: "trash",
                        pos: CGPoint(x: self.view.frame.width / 2 - 140, y:self.view.frame.size.height - 190))
        deleteAlbumButton.addTarget(self, action: #selector(self.pressedDeleteAlbum), for: .touchUpInside)
        deleteAlbumButton.tag = 1234
        self.navigationController?.view.addSubview(deleteAlbumButton)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.navigationController?.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.db.closeListeners()
        
        if let foundView = self.navigationController?.view.viewWithTag(123) {
            (foundView as! UIButton).removeTarget(self, action: #selector(self.pressedAddAlbum), for: .touchUpInside)
        }
        
        if let foundView = self.navigationController?.view.viewWithTag(1234) {
            (foundView as! UIButton).removeTarget(self, action: #selector(self.pressedDeleteAlbum), for: .touchUpInside)
        }
        
        self.navigationController?.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.albums.count
    }
    
    let ALBUM_CELL_ID = "ALBUM_CELL_ID"
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ALBUM_CELL_ID, for: indexPath)
        
        // Configure the cell
        cell.textLabel?.text = albums[indexPath.row].name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let album : SharedAlbum = albums[indexPath.row]
        return album.authorID == db.getCurrentUser().id
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let albumToDelete = albums[indexPath.row]
            db.deleteSharedAlbum(albumID: albumToDelete.id)
        }
    }
    
    let ALBUM_SEGUE_ID = "ALBUM_SEGUE_ID"
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ALBUM_SEGUE_ID {
            let vc = segue.destination as! SharedAlbumVC
            if let indexPath = tableView.indexPathForSelectedRow {
                vc.selectedAlbum = self.albums[indexPath.row]
            }
        }
    }
}
