//
//  DBProvider.swift
//  IORider
//
//  Created by Oscar on 2018/09/04.
//  Copyright © 2018 Oscar. All rights reserved.
//

import Foundation
import FirebaseDatabase

class DBProvider {
    
    private static let _instance = DBProvider()
    
    static var Instance: DBProvider {
        return _instance
    }
    
    var dbRef: DatabaseReference {
        return Database.database().reference()
    }
    
    var ridersRef: DatabaseReference {
        return dbRef.child(Constants.RIDERS)
    }
    
    // request reference
    var requestRef: DatabaseReference {
        return dbRef.child(Constants.CUSTOMER_REQUEST)
    }
    
    // requestAccepted
    var reuestAccepptedRef: DatabaseReference {
        return dbRef.child(Constants.REQUEST_ACCEPTED)
    }
    
    func saveUser(withID: String, email: String, name: String, surname: String,  password: String) {
        
        let data: Dictionary<String, Any> = [Constants.EMAIL: email, Constants.PASSWORD: password, Constants.PRENAME: name, Constants.SURNAME: surname, Constants.isRider: true]
        
        ridersRef.child(withID).child(Constants.DATA).setValue(data)
    }
}
