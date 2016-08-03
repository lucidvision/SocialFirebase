//
//  FeedVC.swift
//  SocialFirebase
//
//  Created by Brian Park on 7/31/16.
//  Copyright © 2016 Brian Park. All rights reserved.
//

import UIKit
import Firebase
import SwiftKeychainWrapper

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addImage: FancyCircleView!
    @IBOutlet weak var captionField: FancyField!
    
    var posts = [Post]()
    var imagePicker: UIImagePickerController!
    static var imageCache: NSCache = NSCache()
    var imageSelected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        DataService.ds.REF_POSTS.observeEventType(.Value, withBlock: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        let post = Post(postKey: key, postData: postDict)
                        self.posts.append(post)
                    }
                }
            }
            self.tableView.reloadData()
        })
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let post = posts[indexPath.row]
        if let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as? PostCell {
            if let img = FeedVC.imageCache.objectForKey(post.imageUrl) {
                cell.configureCell(post, img: img as? UIImage)
            } else {
                cell.configureCell(post)
            }
            return cell
        } else {
            return PostCell()
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            addImage.image = image
            imageSelected = true
        } else {
            print("BRIAN: A valid image wasn't selected")
        }
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func postToFirebase(imgUrl: String) {
        let post: Dictionary<String, AnyObject> = [
            "caption": captionField.text!,
            "imageUrl": imgUrl,
            "likes": 0
        ]
        
        let firebasePost = DataService.ds.REF_POSTS.childByAutoId()
        firebasePost.setValue(post)
        
        captionField.text = ""
        imageSelected = false
        addImage.image = UIImage(named: "add-image")
        
        tableView.reloadData()
    }
    
    @IBAction func signOutTapped(sender: AnyObject) {
        let keychainResult = KeychainWrapper.removeObjectForKey(KEY_UID)
        try! FIRAuth.auth()?.signOut()
        performSegueWithIdentifier("goToSignIn", sender: nil)
        print("BRIAN: ID removed from keychain \(keychainResult)")
    }
    
    @IBAction func addImageTapped(sender: AnyObject) {
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func postBtnTapped(sender: AnyObject) {
        guard let caption = captionField.text where caption != "" else {
            print("BRIAN: Caption must be entered")
            return
        }
        
        guard let img = addImage.image where imageSelected == true else {
            print("BRIAN: An image must be selected")
            return
        }
        
        if let imgData = UIImageJPEGRepresentation(img, 0.2) {
            let imgUid = NSUUID().UUIDString
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            DataService.ds.REF_POST_IMAGES.child(imgUid).putData(imgData, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print("BRIAN: Unable to upload image to Firebase Storage")
                } else {
                    print("BRIAN: Successfully uploaded image to Firebase Storage")
                    let downloadURL = metadata?.downloadURL()?.absoluteString
                    if let url = downloadURL {
                        self.postToFirebase(url)
                    }
                }
            }
        }
    }
}
