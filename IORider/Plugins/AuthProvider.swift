//
//  AuthProvider.swift
//  IORider
//
//  Created by Oscar on 2018/08/30.
//  Copyright © 2018 Oscar. All rights reserved.
//

import Foundation
import FirebaseAuth

typealias LoginHandler = (_ msg: String?) -> Void

struct LoginErrorCode {
    static let INVALID_EMAIL = "Invalid Email address, Please enter a valid email address"
    static let WRONG_PASSWORD = "Wrong Password, Please try again"
    static let PROBLEM_CONNECTING = "We couldn't connect to our Database, Please try again later Or check your network connection"
    static let USER_NOT_FOUND = "User not found, Please Register/Signup"
    static let EMAIL_ALREADY_IN_USE = "This Email is already taken, please use another Email"
    static let WEAK_PASSWORD = "Your Password should be at least 6 characters long"
    static let USER_DISABLED = "Sorry but your account has been disabled, Please contact our company"
}

class AuthProvider {
    
    private static let _instance = AuthProvider()
    
    static var Instance: AuthProvider {
        return _instance
    }
    
    //Login function
    func login(withEmail: String, password: String, loginHandler: LoginHandler?) {
        
        Auth.auth().signIn(withEmail: withEmail, password: password, completion: { (user, error) in
            
            if error != nil {
                self.handleErrors(err: error as! NSError, loginHandler: loginHandler)
            } else {
                loginHandler?(nil)
            }
        })
    }
    
    //Logout function
    func logOut() -> Bool {
        
        if Auth.auth().currentUser != nil {
            do {
                try Auth.auth().signOut()
                
                return true
            } catch {
                
                return false
            }
        }
        return true
    }
    
    //SignUp function
    func signUp(withEmail: String, name: String, surname: String, password: String, loginHandler: LoginHandler?) {
        
        Auth.auth().createUser(withEmail: withEmail, password: password, completion: { (user, error) in
            
            if error != nil {
                
                self.handleErrors(err: error as! NSError, loginHandler: loginHandler)
            } else {
                
                if user != nil {
                    
                    // getting user ID
                    let userID = Auth.auth().currentUser!.uid
                    
                    // store user in databse
                    DBProvider.Instance.saveUser(withID: userID, email: withEmail, name: name, surname: surname, password: password)
                    
                    //login user
                    self.login(withEmail: withEmail, password: password, loginHandler: loginHandler)
                    
                }
            }
        })
    }
    
    private func handleErrors(err: NSError, loginHandler: LoginHandler?) {
        
        if let errCode = AuthErrorCode(rawValue: err.code) {
            
            switch errCode {
                
            case .wrongPassword:
                loginHandler?(LoginErrorCode.WRONG_PASSWORD)
                break
                
            case .invalidEmail:
                loginHandler?(LoginErrorCode.INVALID_EMAIL)
                break
                
            case .userNotFound:
                loginHandler?(LoginErrorCode.USER_NOT_FOUND)
                break
                
            case .emailAlreadyInUse:
                loginHandler?(LoginErrorCode.EMAIL_ALREADY_IN_USE)
                break
                
            case .weakPassword:
                loginHandler?(LoginErrorCode.WEAK_PASSWORD)
                break
                
            case .userDisabled:
                loginHandler?(LoginErrorCode.USER_DISABLED)
                break
                
            default:
                loginHandler?(LoginErrorCode.PROBLEM_CONNECTING)
                break
            }
        }
    }
}
