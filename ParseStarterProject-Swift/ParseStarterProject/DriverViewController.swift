//
//  DriverViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Sebastian Brukalo on 11/15/15.
//  Copyright © 2015 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit

class DriverViewController: UITableViewController, CLLocationManagerDelegate {
    
    var usernames = [String]()
    var locations = [CLLocationCoordinate2D]()
    var distances = [CLLocationDistance]()
    
    var locationManager:CLLocationManager!
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location:CLLocationCoordinate2D = manager.location!.coordinate
        print("locations = \(location.latitude) \(location.longitude)")
        
        self.latitude = location.latitude
        self.longitude = location.longitude
        
        var query = PFQuery(className:"driverLocation")
        query.whereKey("username", equalTo:PFUser.currentUser()!.username!)
        
        
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            
            if error == nil {
                
                if var objects = objects as? [PFObject]! {
                    
                    if objects.count > 0 {
                        
                        for object in objects {
                            
                            
                            var query = PFQuery(className:"driverLocation")
                            query.getObjectInBackgroundWithId(object.objectId!) {
                                (object: PFObject?, error: NSError?) -> Void in
                                if error != nil {
                                    print(error)
                                } else if let object = object {
                                    
                                    object["driverLocation"] = PFGeoPoint(latitude: location.latitude, longitude: location.longitude)
                                    object.saveInBackground()
                                    
                                }
                            }                            
                            
                        }
                    }
                        
                    else {
                        
                        var driverLocation = PFObject(className:"driverLocation")
                        driverLocation["username"] = PFUser.currentUser()?.username
                        driverLocation["driverLocation"] = PFGeoPoint(latitude: location.latitude, longitude: location.longitude)
                        driverLocation.saveInBackground()
                        
                    }
                } else {
                    // Log details of the failure
                    print(error)
                }
            }}
        
        
        query = PFQuery(className:"riderRequest")
        query.whereKey("location", nearGeoPoint: PFGeoPoint(latitude: location.latitude, longitude: location.longitude))
        query.limit = 10
        query.findObjectsInBackgroundWithBlock {
            
            (objects: [PFObject]?, error: NSError?) -> Void in
            
            if error == nil {
                
                if let objects = objects as? [PFObject]! {
                    
                    self.usernames.removeAll()
                    self.locations.removeAll()
                    
                    for object in objects {
                        
                        if object["driverResponded"] == nil {
                            
                            if let username = object["username"] as? String {
                                
                                self.usernames.append(username)
                            }
                            
                            if let returnedLocation = object["location"] as? PFGeoPoint {
                                
                                let requestLocation = CLLocationCoordinate2DMake(returnedLocation.latitude, returnedLocation.longitude)
                                self.locations.append(requestLocation)
                                
                                let requestCLLocation = CLLocation(latitude: requestLocation.latitude, longitude: requestLocation.longitude)
                                let driverCLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                                let distance = driverCLLocation.distanceFromLocation(requestCLLocation)
                                self.distances.append(distance/1000)
                                
                            }
                            
                        }
                    }
                    
                    self.tableView.reloadData()
                }
            } else {
                // Log details of the failure
                print(error)
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return usernames.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        var distanceDouble = Double(distances[indexPath.row])
        var roundedDistance = Double(round(distanceDouble * 10) / 10)
        cell.textLabel?.text = usernames[indexPath.row] + " - " + String(roundedDistance) + "km away"
        
        return cell
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "logoutDriver" {
            
            navigationController?.setNavigationBarHidden(navigationController?.navigationBarHidden == false, animated: true)
            PFUser.logOut()
            
        } else if segue.identifier == "showViewRequests" {
            
            if let destination = segue.destinationViewController as? RequestViewController {
                
                destination.requestLocation = locations[(tableView.indexPathForSelectedRow?.row)!]
                destination.requestUsername = usernames[(tableView.indexPathForSelectedRow?.row)!]
            }
        }
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return false if you do not want the specified item to be editable.
    return true
    }
    */
    
    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
    // Delete the row from the data source
    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    } else if editingStyle == .Insert {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    }
    */
    
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
    
    }
    */
    
    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return false if you do not want the item to be re-orderable.
    return true
    }
    */
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
   }
