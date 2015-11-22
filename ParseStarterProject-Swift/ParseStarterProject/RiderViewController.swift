//
//  RiderViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Sebastian Brukalo on 11/14/15.
//  Copyright © 2015 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit

class RiderViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet var map: MKMapView!
    
    var riderRequestActive = false
    var driverOnTheWay = false
    
    var locationManager:CLLocationManager!
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0
    
    @IBOutlet var callUberButton: UIButton!
    @IBAction func callUber(sender: AnyObject) {
        
        
        if riderRequestActive == false {
            
            
            var riderRequest = PFObject(className:"riderRequest")
            riderRequest["username"] = PFUser.currentUser()?.username
            riderRequest["location"] = PFGeoPoint(latitude: latitude, longitude: longitude)
            
            riderRequest.saveInBackgroundWithBlock {
                (success: Bool, error: NSError?) -> Void in
                if (success) {
                    
                    self.callUberButton.setTitle("Cancel Uber", forState: UIControlState.Normal)
                    
                    
                } else {
                    
                    var alert = UIAlertController(title: "Could not call Uber", message: "Please try again", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                }
            }
            
            riderRequestActive = true
            
        } else {
            
            self.callUberButton.setTitle("Call Uber", forState: UIControlState.Normal)
            
            riderRequestActive = false
            var query = PFQuery(className:"riderRequest")
            query.whereKey("username", equalTo:PFUser.currentUser()!.username!)
            query.findObjectsInBackgroundWithBlock {
                (objects: [PFObject]?, error: NSError?) -> Void in
                
                if error == nil {
                    // The find succeeded.
                    print("Successfully retrieved \(objects!.count) scores.")
                    
                    // Do something with the found objects
                    if let objects = objects as? [PFObject]! {
                        for object in objects {
                            object.deleteInBackground()
                        }
                    }
                } else {
                    // Log details of the failure
                    print(error)
                }
            }
            
        }
        
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //  locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var location:CLLocationCoordinate2D = manager.location!.coordinate
        // print("locations = \(location.latitude) \(location.longitude)")
        
        self.latitude = location.latitude
        self.longitude = location.longitude
        
        var query = PFQuery(className:"riderRequest")
        query.whereKey("username", equalTo:PFUser.currentUser()!.username!)
        
        query.findObjectsInBackgroundWithBlock {
            
            (objects: [PFObject]?, error: NSError?) -> Void in
            
            if error == nil {
                
                if let objects = objects as? [PFObject]! {
                    
                    
                    for object in objects {
                        
                        if let driverUsername = object["driverResponded"] {
                            
                            
                            var query = PFQuery(className:"driverLocation")
                            query.whereKey("username", equalTo:driverUsername)
                            
                            query.findObjectsInBackgroundWithBlock {
                                
                                (objects: [PFObject]?, error: NSError?) -> Void in
                                
                                if error == nil {
                                    
                                    if let objects = objects as? [PFObject]! {
                                        
                                        
                                        for object in objects {
                                            
                                            if let driverLocation = object["driverLocation"] as? PFGeoPoint {
                                                
                                                
                                                let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                                let userCLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                                                
                                                let distanceMeters = userCLLocation.distanceFromLocation(driverCLLocation)
                                                let distanceKM = distanceMeters / 1000
                                                let roundedTwoDigitDistance = Double(round(distanceKM * 10) / 10 )
                                                
                                                
                                                self.callUberButton.setTitle("Driver is \(roundedTwoDigitDistance) km away!", forState: UIControlState.Normal)
                                                
                                                
                                                self.driverOnTheWay = true
                                                
                                                let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                                                var latDelta = abs(driverLocation.latitude - location.latitude) * 2 + 0.05
                                                var lonDelta = abs(driverLocation.longitude - location.longitude) * 2 + 0.05
                                                
                                                
                                                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
                                                
                                                
                                                
                                                
                                                self.map.setRegion(region, animated: true)
                                                self.map.removeAnnotations(self.map.annotations)
                                                var pinLocation : CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                                                var objectAnnotation = MKPointAnnotation()
                                                objectAnnotation.coordinate = pinLocation
                                                objectAnnotation.title = "Your location"
                                                self.map.addAnnotation(objectAnnotation)
                                                
                                                
                                                pinLocation = CLLocationCoordinate2DMake(driverLocation.latitude, driverLocation.longitude)
                                                objectAnnotation = MKPointAnnotation()
                                                objectAnnotation.coordinate = pinLocation
                                                objectAnnotation.title = "Driver location"
                                                self.map.addAnnotation(objectAnnotation)

                                                
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        
        if driverOnTheWay == false {
            
            let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            self.map.setRegion(region, animated: true)
            self.map.removeAnnotations(map.annotations)
            var pinLocation : CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.latitude, location.longitude)
            var objectAnnotation = MKPointAnnotation()
            objectAnnotation.coordinate = pinLocation
            objectAnnotation.title = "Your location"
            self.map.addAnnotation(objectAnnotation)
           
        }
        
    }
    
    //    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
    //
    //        var locValue:CLLocationCoordinate2D = manager.location.coordinate
    //
    //        print("locations = \(locValue.latitude) \(locValue.longitude)")
    //
    //    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        print(1)
        if segue.identifier == "logoutRider" {
            print(2)
            
            PFUser.logOut()
            var currentUser = PFUser.currentUser()
            print(currentUser)
            
        }
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
