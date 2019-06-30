//
//  RiderVC.swift
//  IORider
//
//  Created by Oscar on 2018/09/03.
//  Copyright © 2018 Oscar. All rights reserved.
//

import UIKit
import MapKit
import FirebaseAuth
import Kingfisher

class RiderVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UberController {
    
    @IBOutlet weak var myMap: MKMapView!
    @IBOutlet weak var centerMapBtn: UIButton!
    @IBOutlet weak var requestUberButton: UIButton!
    @IBOutlet weak var loadViewCustom: UIView!
    @IBOutlet weak var locateDriverBtn: UIButton!
    @IBOutlet weak var locateDriverImg: UIImageView!
    @IBOutlet weak var smallCarButton: UIButton!
    @IBOutlet weak var carTypeView: UIView!
    @IBOutlet weak var truckButton: UIButton!
    @IBOutlet weak var lorryButton: UIButton!
    @IBOutlet weak var driverProfilePicture: UIImageView!
    @IBOutlet weak var driverInfoView: UIView!
    @IBOutlet weak var driverProfileButton: UIButton!
    @IBOutlet weak var driverNameProfile: UILabel!
    @IBOutlet weak var driverNoProfile: UILabel!
    @IBOutlet weak var driverSkillProfile: UILabel!
    
    private let LOGOUT_SEGUE = "logout"
    
    private var locationManager = CLLocationManager()
    private var userLocation: CLLocationCoordinate2D?
    private var driverLocation: CLLocationCoordinate2D?
    private var canRequest = true
    private var riderCanceledRequest = false
    private var timer = Timer()
    
    var carWasSelected = false
    var truckWasSelected = false
    var lorryWasSelected = false
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    //   MARK: - VIEW WILL APPEAR
    override func viewDidAppear(_ animated: Bool) {
        loadViewCustom.isHidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeLocationManager()
        zoomInMap()
        makeButtonRound()
        getUserPreferredName()
        preventScreenFromSleeping()
        
        UberHandler.Instance.observeMessagesForRider()
        UberHandler.Instance.delegate = self
    }
    
    private func initializeLocationManager() {
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func getUserPreferredName() {
        
        //Get userID
        let userID = Auth.auth().currentUser?.uid
        
        //Getting user preferred name
        DBProvider.Instance.dbRef.child("riders").child(userID!).child("data").observeSingleEvent(of: .value) { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            let username = value?["preferredName"] as? String
            
             UberHandler.Instance.rider = username!
        }
    }
    
    func makeButtonRound() {
        
        //this one was for driver profile picture
        driverProfilePicture.layer.cornerRadius = driverProfilePicture.frame.size.width / 2
        driverProfilePicture.layer.masksToBounds = true
        
        driverProfileButton.layer.cornerRadius = driverProfileButton.frame.size.width / 2
        driverProfileButton.layer.masksToBounds = true
        
        lorryButton.layer.cornerRadius = lorryButton.frame.size.width / 2
        lorryButton.layer.masksToBounds = true
        
        truckButton.layer.cornerRadius = truckButton.frame.size.width / 2
        truckButton.layer.masksToBounds = true
        
        smallCarButton.layer.cornerRadius = smallCarButton.frame.size.width / 2
        smallCarButton.layer.masksToBounds = true
        
        centerMapBtn.layer.cornerRadius = centerMapBtn.frame.size.width / 2
        centerMapBtn.layer.masksToBounds = true
        
        locateDriverBtn.layer.cornerRadius = locateDriverBtn.frame.size.width / 2
        locateDriverBtn.layer.masksToBounds = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        // if we have the coordinates from the locationManager
        if let location = locationManager.location?.coordinate {

            userLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)

            myMap.removeAnnotations(myMap.annotations)
            
            if driverLocation != nil {
                if !canRequest {
                    
                    locateDriverBtn.isHidden = false
                    locateDriverImg.isHidden = false
                    
                    let driverAnnotation = MKPointAnnotation()
                    
                    driverAnnotation.coordinate = driverLocation!
                    driverAnnotation.title = "Drivers Location"
                    
                    myMap.addAnnotation(driverAnnotation)
                    
                    //Drawing route
                    let sourcePlaceMark = MKPlacemark(coordinate: userLocation!)
                    let destinationPlaceMark = MKPlacemark(coordinate: driverLocation!)
                    
                    let directionRequest = MKDirectionsRequest()
                    
                    directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
                    directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
                    directionRequest.transportType = .automobile
                    
                    let directions = MKDirections(request: directionRequest)
                    directions.calculate { (response, error) in
                        
                        guard let directionResponse = response else {
                            if let error = error {
                                print("ERROR could not calculate directions \(error.localizedDescription)")
                            }
                            return
                        }
                        
                        let route = directionResponse.routes[0]
                        self.myMap.add(route.polyline, level: .aboveRoads)
                    }
                }
            }

            let annotation = MKPointAnnotation()

            annotation.coordinate = userLocation!
            annotation.title = "Your Location"

            myMap.addAnnotation(annotation)
            
            self.myMap.delegate = self
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 4.0
        
        return renderer
    }
    
    @objc func updateRidersLocation() {
        
        UberHandler.Instance.updateRiderLocation(lat: userLocation!.latitude, long: userLocation!.longitude)
    }
    
    func canRequest(delegateCalled: Bool) {
        
        if delegateCalled {
            
            requestUberButton.setTitle("Cancel Request", for: .normal)
            canRequest = false
        } else {
            requestUberButton.setTitle("Make Request", for: .normal)
            canRequest = true
        }
    }
    
    func downloadDriverProfilePicture(profilepictureURL: String) {
        
    }
    
    func driverAccepted(requestAccepted: Bool, driverName: String, driverUID: String) {
        
        if !riderCanceledRequest {
            
            if requestAccepted {
                
                //retrieving driver info
                DBProvider.Instance.dbRef.child("drivers").child(driverUID).child("data").observeSingleEvent(of: .value) { (snapshot) in
                    
                    let value = snapshot.value as? NSDictionary
                    let driverName = value?["preferredName"] as? String
                    let driverContact = value?["contact"] as? String
                    let driverSkill = value?["cartype"] as? String
                    
                    self.driverNameProfile.text! = driverName!
                    self.driverNoProfile.text! = driverContact!
                    self.driverSkillProfile.text! = driverSkill!
                    
                    print("this is the driver info \(driverName), \(driverContact), \(driverSkill)")
                }
                
                //downloading driver profile picture using driverUID
                DBProvider.Instance.dbRef.child("drivers").child(driverUID).child("data").observeSingleEvent(of: .value) { (snapshot) in
                    
                    let value = snapshot.value as? NSDictionary
                    let downloadURL = value?["url"] as? String
                    
                    //download profile picture after checking cache
                    self.driverProfilePicture.loadImageUsingCahceWithUrlString(urlString: downloadURL!)
//                    self.driverProfilePicture?.kf.indicatorType = .activity
                }

                
                alertTheUser(title: "Request Accepted", message: " \(driverName) Accepted your Request")
                loadViewCustom.isHidden = true
                hideHUD()
            } else {
                
                self.myMap.removeOverlays(self.myMap.overlays)
                
                locateDriverBtn.isHidden = true
                locateDriverImg.isHidden = true
                carTypeView.isHidden = false
                driverInfoView.isHidden = true
                
                UberHandler.Instance.cancelRequest()
                timer.invalidate()
                alertTheUser(title: "Request Canceled", message: "\(driverName) Canceled the Request")
            }
        }
        riderCanceledRequest = false
    }
    
    //Update driver's location
    func updateDriversLocation(lat: Double, long: Double) {
        
        driverLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
    }
    
    func zoomInMap() {
        
        if let location = locationManager.location?.coordinate {
        
        userLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        
        let region = MKCoordinateRegion(center: userLocation!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        myMap.setRegion(region, animated: true)
        }
    }
    
    @IBAction func closeDriverInfo(_ sender: Any) {
        
        driverInfoView.isHidden = true
    }
    
    @IBAction func showDriverInfo(_ sender: Any) {
        
        driverInfoView.isHidden = false
    }
    
    @IBAction func logout(_ sender: Any) {
        
        if AuthProvider.Instance.logOut() {
            
            if !canRequest {
                UberHandler.Instance.cancelRequest()
                timer.invalidate()
            }
            
            self.performSegue(withIdentifier:self.LOGOUT_SEGUE, sender: nil)
        } else {
            // Probleming logging out
            
            alertTheUser(title: "Logout Error", message: "We could not log you out in the moment, Please try again")
        }
    }
    @IBAction func showWholeRoute(_ sender: Any) {
        
        //Drawing route
        let sourcePlaceMark = MKPlacemark(coordinate: userLocation!)
        let destinationPlaceMark = MKPlacemark(coordinate: driverLocation!)
        
        let directionRequest = MKDirectionsRequest()
        
        directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
        directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            
            guard let directionResponse = response else {
                if let error = error {
                    print("ERROR could not calculate directions \(error.localizedDescription)")
                }
                return
            }
            let route = directionResponse.routes[0]
            self.myMap.add(route.polyline, level: .aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            self.myMap.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
        }
    }
    
    @IBAction func centerLocation(_ sender: Any) {
        
        if let location = locationManager.location?.coordinate {
            
            userLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            
            let region = MKCoordinateRegion(center: userLocation!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            
            myMap.setRegion(region, animated: true)
        }
    }
    
    @IBAction func requestLorry(_ sender: Any) {
        
        lorryWasSelected = true
        truckWasSelected = false
        carWasSelected = false
        requestUberButton.isHidden = false
        lorryButton.backgroundColor = UIColor(red: 255/255, green: 99/255, blue: 0/255, alpha: 1.0)
        smallCarButton.backgroundColor = UIColor(red: 0/255, green: 191/255, blue: 255/255, alpha: 1.0)
        truckButton.backgroundColor = UIColor(red: 0/255, green: 191/255, blue: 255/255, alpha: 1.0)
    }
    
    
    @IBAction func requestTruck(_ sender: Any) {
        
        truckWasSelected = true
        lorryWasSelected = false
        carWasSelected = false
        requestUberButton.isHidden = false
        truckButton.backgroundColor = UIColor(red: 255/255, green: 99/255, blue: 0/255, alpha: 1.0)
        lorryButton.backgroundColor = UIColor(red: 0/255, green: 191/255, blue: 255/255, alpha: 1.0)
        smallCarButton.backgroundColor = UIColor(red: 0/255, green: 191/255, blue: 255/255, alpha: 1.0)
    }
    
    @IBAction func requestCar(_ sender: Any) {
        
        carWasSelected = true
        lorryWasSelected = false
        truckWasSelected = false
        requestUberButton.isHidden = false
        smallCarButton.backgroundColor = UIColor(red: 255/255, green: 99/255, blue: 0/255, alpha: 1.0)
        lorryButton.backgroundColor = UIColor(red: 0/255, green: 191/255, blue: 255/255, alpha: 1.0)
        truckButton.backgroundColor = UIColor(red: 0/255, green: 191/255, blue: 255/255, alpha: 1.0)
    }
    
    @IBAction func makeRequest(_ sender: Any) {
        
        //perform this when customer wants a car driver
        if carWasSelected == true {
            if userLocation != nil {
                if canRequest {
                    UberHandler.Instance.requestUber(latitude: Double(userLocation!.latitude), longitude: Double(userLocation!.longitude), carType: "Car")
                    loadViewCustom.isHidden = false
                    carTypeView.isHidden = true
                    LottieActivityIndicatorForReuest()
                    
                    timer = Timer.scheduledTimer(timeInterval: TimeInterval(10), target: self, selector: #selector(RiderVC.updateRidersLocation), userInfo: nil, repeats: true)
                    
                    self.myMap.removeOverlays(self.myMap.overlays)
                } else {
                    locateDriverBtn.isHidden = true
                    locateDriverImg.isHidden = true
                    riderCanceledRequest = true
                    carTypeView.isHidden = false
                    driverInfoView.isHidden = true
                    UberHandler.Instance.cancelRequest()
                    timer.invalidate()
                    
                    self.myMap.removeOverlays(self.myMap.overlays)
                }
            }
        }
        
        //perform this when customer wants a truck driver
        if truckWasSelected == true {
            if userLocation != nil {
                if canRequest {
                    UberHandler.Instance.requestUber(latitude: Double(userLocation!.latitude), longitude: Double(userLocation!.longitude), carType: "Van")
                    loadViewCustom.isHidden = false
                    carTypeView.isHidden = true
                    LottieActivityIndicatorForReuest()
                    
                    timer = Timer.scheduledTimer(timeInterval: TimeInterval(10), target: self, selector: #selector(RiderVC.updateRidersLocation), userInfo: nil, repeats: true)
                    
                    self.myMap.removeOverlays(self.myMap.overlays)
                } else {
                    locateDriverBtn.isHidden = true
                    locateDriverImg.isHidden = true
                    riderCanceledRequest = true
                    carTypeView.isHidden = false
                    UberHandler.Instance.cancelRequest()
                    timer.invalidate()
                    
                    self.myMap.removeOverlays(self.myMap.overlays)
                }
            }
        }
        
        //perform this when customer wants a lorry driver
        if lorryWasSelected == true {
            if userLocation != nil {
                if canRequest {
                    UberHandler.Instance.requestUber(latitude: Double(userLocation!.latitude), longitude: Double(userLocation!.longitude), carType: "Lorry")
                    loadViewCustom.isHidden = false
                    carTypeView.isHidden = true
                    LottieActivityIndicatorForReuest()
                    
                    timer = Timer.scheduledTimer(timeInterval: TimeInterval(10), target: self, selector: #selector(RiderVC.updateRidersLocation), userInfo: nil, repeats: true)
                    
                    self.myMap.removeOverlays(self.myMap.overlays)
                } else {
                    locateDriverBtn.isHidden = true
                    locateDriverImg.isHidden = true
                    riderCanceledRequest = true
                    carTypeView.isHidden = false
                    UberHandler.Instance.cancelRequest()
                    timer.invalidate()
                    
                    self.myMap.removeOverlays(self.myMap.overlays)
                }
            }
        }
    }
    
    private func alertTheUser(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
}



