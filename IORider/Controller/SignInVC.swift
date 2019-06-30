//
//  SignInVC.swift
//  IORider
//
//  Created by Oscar on 2018/08/30.
//  Copyright © 2018 Oscar. All rights reserved.
//

import UIKit
import FirebaseAuth
import MessageUI
import SystemConfiguration

class SignInVC: UIViewController, UITextFieldDelegate, MFMailComposeViewControllerDelegate {
    
    //    MARK: - let PROPERTIES
    private let RIDER_SEGUE = "RiderVC"
    
    //    MARK: - var PROPERTIES
    var buttonSelected: Bool = false
    
    //    MARK: - IBOUTLETS
    @IBOutlet weak var passwordBtn: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loadViewCustom: UIView!
    
    
    //   MARK: - VIEW WILL APPEAR
    override func viewDidAppear(_ animated: Bool) {
        checkIfUserIsAlreadyLoggedIn()
        checkInternetConnection()
        loadViewCustom.isHidden = true
    }

    //    MARK: - VIEW DID LOAD
    override func viewDidLoad() {
        super.viewDidLoad()

        self.emailTextField.delegate = self
        self.passwordTextField.delegate = self
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    //Compose email
    func configureMailController() -> MFMailComposeViewController {
        
        let mailComposerVC = MFMailComposeViewController ()
        
        mailComposerVC.mailComposeDelegate = self
        mailComposerVC.setToRecipients(["nengovhelaandy@gmail.com"])
        mailComposerVC.setSubject("IORider app")
        mailComposerVC.setMessageBody("", isHTML: false)
        
        return mailComposerVC
    }
    
    // MARK: - Check if user is logged in
    func checkIfUserIsAlreadyLoggedIn() {
        if Auth.auth().currentUser?.uid != nil {
            print("User is already logged in")
            
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let RiderViewcontroller : RiderVC = mainStoryboard.instantiateViewController(withIdentifier: "RiderVC") as! RiderVC
            
            self.present(RiderViewcontroller, animated: true, completion: nil)
        } else {
            print("User hasn't logged in")
        }
    }
    
    // MARK: - Display alert if something goes wrong when trying to send an email
    func showMailError() {
        
        let sendMailErrorAlert = UIAlertController(title: "Faild to send email", message: "Something went wrong when trying to send the Email", preferredStyle: .alert)
        let dismiss = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        sendMailErrorAlert.addAction(dismiss)
        self.present(sendMailErrorAlert, animated: true, completion: nil)
    }
    
    // MARK: - Dismiss mail app when done
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    //check internet connection
    func checkInternetConnection(){
        if Reachability.isConnectedToNetwork(){
            print("Internet Connection Available!")
        }else{
            alertTheUser(title: "Connection Error", message: "Please make sure you have Internet Connection")
            
        }
        
    }
    
    // MARK: - Open my website
    @IBAction func openMyWebsite(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://www.inteloscar.co.za")! as URL, options: [:], completionHandler: nil)
    }
    
    // MARK: - Compose mail
    @IBAction func sendEmail(_ sender: Any) {
        
        let mailComposeViewController = configureMailController()
        
        if MFMailComposeViewController.canSendMail(){
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            showMailError()
        }
    }
    
    // MARK: - Change password button when clicked and also change secure text
    @IBAction func pushedPasswordbtn(_ sender: Any) {
    
        passwordTextField.isSecureTextEntry = !passwordTextField.isSecureTextEntry
        
        if buttonSelected == false{
            
            let pressedButtonImage = UIImage(named: "hide") as UIImage!
            passwordBtn.setImage(pressedButtonImage, for: UIControlState.normal)
            buttonSelected = true
        }else if buttonSelected == true{
            let pressedButtonImage = UIImage(named: "showpassio") as UIImage!
            passwordBtn.setImage(pressedButtonImage, for: UIControlState.normal)
            buttonSelected = false
        }
    }
    
    // Login the user
    @IBAction func login(_ sender: Any) {
        
        if emailTextField.text != "" && passwordTextField.text != "" {
            
            LottieActivityIndicator()
            dismissKeyboard()
            
            loadViewCustom.isHidden = false

            AuthProvider.Instance.login(withEmail: emailTextField.text!, password: passwordTextField.text!, loginHandler: { (message) in

                if message != nil {
                    self.loadViewCustom.isHidden = true
                    self.hideHUD()
                    self.alertTheUser(title: "Problem Logging in", message: message!)
                } else {
                    let userID = Auth.auth().currentUser?.uid
                    
                    //Getting isRider Bool
                    DBProvider.Instance.dbRef.child("riders").child(userID!).child("data").observeSingleEvent(of: .value) { (snapshot) in
                        
                        let value = snapshot.value as? NSDictionary
                        let riderOrDriver = value?["isRider"] as? Bool
                        
                        if riderOrDriver == true {
                            self.hideHUD()
                            self.passwordTextField.text = ""
                            self.performSegue(withIdentifier:self.RIDER_SEGUE, sender: nil)
                            print("Login successful")
                        }else {
                            self.emailTextField.text = ""
                            self.passwordTextField.text = ""
                            self.hideHUD()
                            self.loadViewCustom.isHidden = true
                            AuthProvider.Instance.logOut()
                            self.alertTheUser(title: "You are not a Customer", message: "Please use the Driver App")
                        }
                    }
                }
            })
        } else {

            alertTheUser(title: "Email and Password are required", message: "Please make sure you have filled in both the Email and Password fields")
        }
    }
    
    // MARK: - Extra Functions
    private func alertTheUser(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
}
