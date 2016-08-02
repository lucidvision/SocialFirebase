//
//  ViewController.swift
//  SocialFirebase
//
//  Created by Brian Park on 7/31/16.
//  Copyright © 2016 Brian Park. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import SwiftKeychainWrapper

class SignInVC: UIViewController {

    @IBOutlet weak var emailField: FancyField!
    @IBOutlet weak var pwdField: FancyField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        if let _ = KeychainWrapper.stringForKey(KEY_UID) {
            performSegueWithIdentifier("goToFeed", sender: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func facebookBtnTapped(sender: AnyObject) {
        
        let facebookLogin = FBSDKLoginManager()
        
        facebookLogin.logInWithReadPermissions(["email"], fromViewController: self, handler: { (result, error) in
            if error != nil {
                print("BRIAN: Could not authenticate with Facebook")
            } else if result?.isCancelled == true {
                print("BRIAN: User cancelled Facebook authentication")
            } else {
                print("BRIAN: Successfully authenticated with Facebook")
                let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
                self.firebaseAuth(credential)
            }
        })
    }
    
    func firebaseAuth(credential: FIRAuthCredential) {
        FIRAuth.auth()?.signInWithCredential(credential, completion: { (user, error) in
            if error != nil {
                print("BRIAN: Unable to authenticate with Firebase facebook - \(error)")
            } else {
                print("BRIAN: Successfully authenticated with Firebase")
                if let user = user {
                    let userData = ["provider": credential.provider]
                    self.completeSignIn(user.uid, userData: userData)
                }
            }
        })
    }
    
    @IBAction func signInTapped(sender: AnyObject) {
        if let email = emailField.text, let pwd = pwdField.text {
            FIRAuth.auth()?.signInWithEmail(email, password: pwd, completion: { (user, error) in
                if error == nil {
                    print("BRIAN: Email user authenticated with Firebase")
                    if let user = user {
                        let userData = ["provider": user.providerID]
                        self.completeSignIn(user.uid, userData: userData)
                    }
                } else {
                    FIRAuth.auth()?.createUserWithEmail(email, password: pwd, completion: { (user, error) in
                        if error != nil {
                            print("BRIAN: Unable to authenticate with Firebase email - \(error)")
                        } else {
                            print("BRIAN: Successfully authenticated with Firebase")
                            if let user = user {
                                let userData = ["provider": user.providerID]
                                self.completeSignIn(user.uid, userData: userData)
                            }
                        }
                    })
                }
            })
        }
    }
    
    func completeSignIn(id: String, userData: Dictionary<String, String>) {
        DataService.ds.createFirebaseDBUser(id, userData: userData)
        let keyChainResult = KeychainWrapper.setString(id, forKey: KEY_UID)
        performSegueWithIdentifier("goToFeed", sender: nil)
        print("BRIAN: Data saved to keychain \(keyChainResult)")
    }
 }

