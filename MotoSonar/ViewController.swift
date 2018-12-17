//
//  ViewController.swift
//  MotoSonar
//
//  Created by Nick Raff on 12/12/18.
//  Copyright © 2018 Nick Raff. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Firebase
import FirebaseAuth
import GeoFire
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    var fireRef: DatabaseReference!
    var geoRef: DatabaseReference!
    var authEndResult: AuthDataResult!
    var geoFueg: GeoFire!
    var lastLocation: CLLocation!
    var isDriver = true
    
    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //set up firebase
        fireRef = Database.database().reference()
        geoRef = Database.database().reference().child("motorists")
        geoFueg = GeoFire(firebaseRef: geoRef)
        
        //authenticate user
        Auth.auth().signInAnonymously() {(authResult, error) in
            if let error = error {
                print("Anon sign in faild:", error.localizedDescription)
            } else {
                self.authEndResult = authResult
                let uid = authResult?.user.uid
                print("Signed in with uid:", uid!)
            }
        }
        
        //attach location manager
        locationManager.delegate = self;
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 1. status is not determined
        if CLLocationManager.authorizationStatus() == .notDetermined {
            print("didn't make the request location call")
            locationManager.requestAlwaysAuthorization()
        }
        // 2. authorization were denied
        else if CLLocationManager.authorizationStatus() == .denied {
            let message = "Location services were previously denied. Please enable location services for this app in Settings."
            showAlert(message: message)
        }
        // 3. we do have authorization
        else if CLLocationManager.authorizationStatus() == .authorizedAlways {
            print("Location authorization already provided")
        }
    }

    
    //MARK: IBActions
    @IBAction func drive_btn(_ sender: Any) {
//        let center = CLLocation(latitude: 37.7832889, longitude: -122.4056973)
//        setQuery(center: center, radius: 0.4).observe(.keyEntered, with: {(key: String!, location: CLLocation!) in
//            print("Key: '\(key!)' entered the search area and is at location '\(location!)'")
//        })
        isDriver = true
        locationManager.startUpdatingLocation()
    }
    
    @IBAction func ride_btn(_ sender: Any) {
        isDriver = false
        locationManager.startUpdatingLocation()
    }
    
    //MARK: Helper Functions
    func setQuery(center: CLLocation, radius: Double) -> GFQuery {
        //CLLocation(latitude: 37.7832889, longitude: -122.4056973)
        // Query locations at [37.7832889, -122.4056973] with a radius of 600 meters
        let query = geoFueg.query(at: center, withRadius: radius)
        return query
    }
    
    func getLocation() -> CLLocation {
        if let newLocation = locationManager.location {
            lastLocation = newLocation
            return newLocation
        } else {
            return lastLocation
        }
    }
    
    func setLocation() {
        let newLocation = getLocation()
        geoFueg.setLocation(CLLocation(latitude: newLocation.coordinate.latitude, longitude: newLocation.coordinate.longitude), forKey: self.authEndResult.user.uid) { (error) in
            if (error != nil) {
                print("An error occured: \(error!)")
            } else {
                print("Saved location successfully")
            }
        }
    }
    
    func showAlert(message: String){
        let alert = UIAlertController(title: "Whoops", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        if isDriver {
            print("is driver logic")
            setQuery(center: userLocation, radius: 0.4).observe(.keyEntered, with: {(key: String!, location: CLLocation!) in
                print("Key: '\(key!)' entered the search area and is at location '\(location!)'")
            })
        } else {
            print("is motorcyclist logic")
            geoFueg.setLocation(userLocation, forKey: self.authEndResult.user.uid) { (error) in
                if (error != nil) {
                    print("An error occured: \(error!)")
                } else {
                    print("Saved location successfully")
                }
            }
        }
    }
    
    
}

