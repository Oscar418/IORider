//
//  UberHandler.swift
//  IORider
//
//  Created by Oscar on 2018/09/07.
//  Copyright © 2018 Oscar. All rights reserved.
//

import Foundation
import FirebaseDatabase

protocol UberController: class{
    func canRequest(delegateCalled: Bool)
    func driverAccepted(requestAccepted: Bool, driverName: String, driverUID: String)
    func updateDriversLocation(lat: Double, long: Double)
}

class UberHandler {
    
    private static let _instance = UberHandler()
    
    weak var delegate: UberController?
    
    var rider = ""
    var driver = ""
    var driver_id = ""
    var rider_id = ""
    
    static var Instance : UberHandler {
        return _instance
    }
    
    func observeMessagesForRider() {
        
        //Customer requested
        DBProvider.Instance.requestRef.observe(DataEventType.childAdded) { (snapshot: DataSnapshot) in
            
            if let data = snapshot.value as? NSDictionary {
                if let name = data[Constants.NAME] as? String {
                    if name == self.rider {
                        self.rider_id = snapshot.key
                        self.delegate?.canRequest(delegateCalled: true)
                    }
                }
            }
        }
        
        //Customer canceled
        DBProvider.Instance.requestRef.observe(DataEventType.childRemoved) { (snapshot: DataSnapshot) in
            
            if let data = snapshot.value as? NSDictionary {
                if let name = data[Constants.NAME] as? String {
                    if name == self.rider {
                        self.delegate?.canRequest(delegateCalled: false)
                    }
                }
            }
        }
        
        // Driver accetped the request
        DBProvider.Instance.reuestAccepptedRef.observe(DataEventType.childAdded) { (snapshot: DataSnapshot) in
            
            if let data = snapshot.value as? NSDictionary {
                
                if let name = data[Constants.NAME] as? String {
                    if let driverUID = data[Constants.DRIVERUID] as? String {
                        if self.driver_id == "" {
                            if self.driver == "" {
                                self.driver = name
                                self.driver_id = driverUID
                                self.delegate?.driverAccepted(requestAccepted: true, driverName: self.driver, driverUID: self.driver_id)
                            }
                        }
                    }
                }
            }
        }
        
        // Driver canceled
        DBProvider.Instance.reuestAccepptedRef.observe(DataEventType.childRemoved) { (snapshot: DataSnapshot) in
            
            if let data = snapshot.value as? NSDictionary {
                if let name = data[Constants.NAME] as? String {
                    if let driverUID = data[Constants.DRIVERUID] as? String {
                        if self.driver_id == "" {
                            if name == self.driver {
                                self.driver_id = driverUID
                                self.driver = ""
                                self.delegate?.driverAccepted(requestAccepted: false, driverName: name, driverUID: self.driver_id)
                            }
                        }
                    }
                }
            }
        }
        
        // Driver updating location
        DBProvider.Instance.reuestAccepptedRef.observe(DataEventType.childChanged) { (snapshot: DataSnapshot) in
            
            if let data = snapshot.value as? NSDictionary {
                if let name = data[Constants.NAME] as? String {
                    if name == self.driver {
                        if let lat = data[Constants.LATITUDE] as? Double {
                            if let long = data[Constants.LONGITUDE] as? Double {
                                
                                self.delegate?.updateDriversLocation(lat: lat, long: long)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func requestUber(latitude: Double, longitude: Double, carType: String) {
        
        let data: Dictionary<String, Any> = [Constants.NAME: rider, Constants.LATITUDE: latitude, Constants.LONGITUDE: longitude, Constants.CARTYPE: carType]
        
        DBProvider.Instance.requestRef.childByAutoId().setValue(data)
    }
    
    func cancelRequest() {
        
        DBProvider.Instance.requestRef.child(rider_id).removeValue()
    }
    
    func updateRiderLocation(lat: Double, long: Double) {
        
        DBProvider.Instance.requestRef.child(rider_id).updateChildValues([Constants.LATITUDE: lat, Constants.LONGITUDE: long])
    }
}
