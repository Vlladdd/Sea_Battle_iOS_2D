//
//  RegistrationViewController.swift
//  Sea Battle 2D iOS
//
//  Created by Vlad Nechyporenko on 18.02.2022.
//  Copyright © 2022 Vlad Nechyporenko. All rights reserved.
//

import UIKit
import GoogleSignIn
import FirebaseCore
import Firebase
import FirebaseAuth

// VC that represents authorization in app by Google account
class AuthorizationViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    @IBOutlet weak var signInButton: GIDSignInButton!
    
    override func viewDidLayoutSubviews() {
        signInButton.style = .wide
    }
    
    @IBAction func signIn(_ sender: GIDSignInButton) {
        /* check for user's token */
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
              if error != nil || user == nil {
                // Show the app's signed-out state.
              } else {
                  self?.performSegue(withIdentifier: "Main Menu", sender: nil)
                // Show the app's signed-in state.
              }
            }
        }
        else {
            guard let clientID = FirebaseApp.app()?.options.clientID else { return }
            
            // Create Google Sign In configuration object.
            let config = GIDConfiguration(clientID: clientID)
            
            // Start the sign in flow!
            GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [unowned self] user, error in
                
                if let error = error {
                    // ...
                    print(error)
                    return
                }
                
                guard
                    let authentication = user?.authentication,
                    let idToken = authentication.idToken
                else {
                    return
                }
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                               accessToken: authentication.accessToken)
                
                // ...
                
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        let authError = error as NSError
                        if authError.code == AuthErrorCode.secondFactorRequired.rawValue {
                            // The user is a multi-factor user. Second factor challenge is required.
                            let resolver = authError
                                .userInfo[AuthErrorUserInfoMultiFactorResolverKey] as! MultiFactorResolver
                            var displayNameString = ""
                            for tmpFactorInfo in resolver.hints {
                                displayNameString += tmpFactorInfo.displayName ?? ""
                                displayNameString += " "
                            }
                            self.showTextInputPrompt(
                                withMessage: "Select factor to sign in\n\(displayNameString)",
                                completionBlock: { userPressedOK, displayName in
                                    var selectedHint: PhoneMultiFactorInfo?
                                    for tmpFactorInfo in resolver.hints {
                                        if displayName == tmpFactorInfo.displayName {
                                            selectedHint = tmpFactorInfo as? PhoneMultiFactorInfo
                                        }
                                    }
                                    PhoneAuthProvider.provider()
                                        .verifyPhoneNumber(with: selectedHint!, uiDelegate: nil,
                                                           multiFactorSession: resolver
                                                            .session) { verificationID, error in
                                            if error != nil {
                                                print(
                                                    "Multi factor start sign in failed. Error: \(error.debugDescription)"
                                                )
                                            } else {
                                                self.showTextInputPrompt(
                                                    withMessage: "Verification code for \(selectedHint?.displayName ?? "")",
                                                    completionBlock: { userPressedOK, verificationCode in
                                                        let credential: PhoneAuthCredential? = PhoneAuthProvider.provider()
                                                            .credential(withVerificationID: verificationID!,
                                                                        verificationCode: verificationCode!)
                                                        let assertion: MultiFactorAssertion? = PhoneMultiFactorGenerator
                                                            .assertion(with: credential!)
                                                        resolver.resolveSignIn(with: assertion!) { authResult, error in
                                                            if error != nil {
                                                                print(
                                                                    "Multi factor finalize sign in failed. Error: \(error.debugDescription)"
                                                                )
                                                            } else {
                                                                self.navigationController?.popViewController(animated: true)
                                                            }
                                                        }
                                                    }
                                                )
                                            }
                                        }
                                }
                            )
                        } else {
                            self.showMessagePrompt(error.localizedDescription)
                            return
                        }
                        // ...
                        return
                    }
                    performSegue(withIdentifier: "Main Menu", sender: nil)
                    // User is signed in
                    // ...
                }
            }
        }
    }

}




