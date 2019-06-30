//
//  MyExtensions.swift
//  IORider
//
//  Created by Oscar on 2018/09/05.
//  Copyright © 2018 Oscar. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration

let imageCache = NSCache<AnyObject, AnyObject>()

var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()

extension UIViewController {
    
    //diable screen timeout
    func preventScreenFromSleeping() {
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    //Show Lottie activity indicator
    func LottieActivityIndicator() {
        let progressHUD = LottieProgressHUD.shared
        progressHUD.animationFileName = "loading_semicircle" //name of the file
        progressHUD.hudHeight = 250 //height of ProgressHUD
        progressHUD.hudWidth = 250  //weight of ProgressHUD
        progressHUD.hudBackgroundColor = UIColor.clear //set background color of ProgressHUD
        progressHUD.borderWidth = 0
        self.view.addSubview(progressHUD)  // add to view
        progressHUD.show()
    }
    
    //Hide Lottie activity indicator
    func hideHUD() {
        let progressHUD = LottieProgressHUD.shared
        progressHUD.hide()
    }
    
    func LottieActivityIndicatorForReuest() {
        let progressHUD = LottieProgressHUD.shared
        progressHUD.animationFileName = "party_penguin" //name of the file
        progressHUD.hudHeight = 200 //height of ProgressHUD
        progressHUD.hudWidth = 200  //weight of ProgressHUD
        progressHUD.hudBackgroundColor = UIColor.clear //set background color of ProgressHUD
        progressHUD.borderWidth = 0
        self.view.addSubview(progressHUD)  // add to view
        progressHUD.show()
    }
    
    //Dimiss the keyboard
    func dismissKeyboard() {
        view.endEditing(true)
    }

    //Check internt connection
    public class Reachability {
        
        class func isConnectedToNetwork() -> Bool {
            
            var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
            zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
            zeroAddress.sin_family = sa_family_t(AF_INET)
            
            let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                    SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
                }
            }
            
            var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
            if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
                return false
            }
            
            // Working for Cellular and WIFI
            let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
            let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
            let ret = (isReachable && !needsConnection)
            
            return ret
        }
    }
}

extension UIImageView {
    
    func loadImageUsingCahceWithUrlString(urlString: String) {
        
        //check cache for image first
        if let cacheImage = imageCache.object(forKey: urlString as AnyObject) as? UIImage {
            
            self.image = cacheImage
            return
        }
        
        //otherwise download new picture
        let finalDownloadURL = URL(string: urlString)
        
        URLSession.shared.dataTask(with: finalDownloadURL!, completionHandler: { (data, response, error) in
            
            if error != nil {
                print("this is the error that occured when trying to download the driver profile picture \(error)")
                return
            }
            
            DispatchQueue.main.async {
                
                if let downloadedImage = UIImage(data: data!) {
                    
                    imageCache.setObject(downloadedImage, forKey: urlString as AnyObject)
                    
                    self.image = downloadedImage
                }
            }
        }).resume()
    }
}
