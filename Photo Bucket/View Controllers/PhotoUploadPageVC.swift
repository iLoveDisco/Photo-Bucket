
import UIKit

extension PhotoUploadPageVC : ImagePickerDelegate {
    func didSelect(image: UIImage?) {
        self.picView.image = image
    }
}

class PhotoUploadPageVC : UIViewController {
    var album : SharedAlbum!
    
    @IBOutlet weak var picView: UIImageView!
    
    @IBAction func pressedUpdate(_ sender: Any) {
        db.uploadPic(type: "photos", img: picView.image!) { (url) in
            self.db.createPhoto(sharedAlbumID: self.album.id, caption: self.captionTF.text!, url: url)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func pressedUpload(_ sender: UIButton) {
        self.imagePicker.present(from: sender)
    }
    
    @IBOutlet weak var captionTF: UITextField!
    
    var imagePicker : ImagePickerVC!
    let db : MyDatabase = MyFirebaseDB()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialize the image picker
        self.imagePicker = ImagePickerVC(presentationController: self, delegate: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.db.closeListeners()
    }
    
}
