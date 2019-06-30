//
//  RegistrationViewController.swift
//  IORider
//
//  Created by Oscar on 2018/09/13.
//  Copyright © 2018 Oscar. All rights reserved.
//

import UIKit

class RegistrationViewController: UIViewController, UIScrollViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate  {
    
    //    MARK: - let PROPERTIES
    private let RIDER_SEGUE = "RiderVC"
    private let typeOfCar = ["Select type of driver","Car", "Van", "Lorry"]
    
    //    MARK: - var PROPERTIES
    var buttonSelected: Bool = false

    @IBOutlet weak var imageViewCustom: UIImageView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var surnameTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var passwordBtn: UIButton!
    @IBOutlet weak var RegScrollView: UIScrollView!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextFIeld: UITextField!
    @IBOutlet weak var loadViewCustom: UIView!
    
    //   MARK: - VIEW WILL APPEAR
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addObservers()
    }
    //   MARK: - VIEW WILL DISAPPEAR
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        removeObservers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        RegScrollView.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapView(gesture:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func signup(_ sender: Any) {
        
        if emailTextField.text != "" && passwordTextField.text != "" && nameTextField.text != "" && surnameTextField.text != ""{
            
            if passwordTextField.text! == confirmPasswordTextFIeld.text! {
                
                LottieActivityIndicator()
                
                dismissKeyboard()
                
                loadViewCustom.isHidden = false
                
                AuthProvider.Instance.signUp(withEmail: emailTextField.text!, name: nameTextField.text!, surname: surnameTextField.text!, password: passwordTextField.text!, loginHandler: { (message) in
                    
                    if message != nil {
                        self.hideHUD()
                        self.loadViewCustom.isHidden = true
                        self.alertTheUser(title: "The was a problem registering you", message: message!)
                    } else {
                        self.hideHUD()
                        self.passwordTextField.text = ""
                        self.performSegue(withIdentifier:self.RIDER_SEGUE, sender: nil)
                        print("Creating user successful")
                    }
                })
            } else {
                alertTheUser(title: "Password Error", message: "Entered Password and Confirm Password do not match")
            }
        } else {
            alertTheUser(title: "Some Fields Are Missing", message: "Please make sure you have filled in everything")
        }
    }
    
    
    @IBAction func passwordBtnChange(_ sender: Any) {
        
        passwordTextField.isSecureTextEntry = !passwordTextField.isSecureTextEntry
        confirmPasswordTextFIeld.isSecureTextEntry = !confirmPasswordTextFIeld.isSecureTextEntry
        
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
    
    @objc func didTapView(gesture: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    func addObservers() {
        NotificationCenter.default.addObserver(forName: .UIKeyboardWillShow, object: nil, queue: nil) {
            notification in
            self.keyboardWillShow(notification: notification)
        }
        
        NotificationCenter.default.addObserver(forName: .UIKeyboardWillHide, object: nil, queue: nil) {
            notification in
            self.keyboardWillHide(notification: notification)
        }
    }
    func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    func keyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let frame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                return
        }
        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: frame.height, right: 0)
        RegScrollView.contentInset =  contentInset
    }
    func keyboardWillHide(notification: Notification) {
        RegScrollView.contentInset = UIEdgeInsets.zero
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x != 0 {
            scrollView.contentOffset.x = 0
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return typeOfCar[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return typeOfCar.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        var ex = typeOfCar[row]
        
        print("this is the selected one \(ex)")
    }
    
    //Alert
    private func alertTheUser(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
}
