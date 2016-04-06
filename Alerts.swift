//
//  Alerts.swift
//  CouchJump
//
//  Created by Eric McGaughey on 11/3/15.
//  Copyright © 2015 Eric McGaughey. All rights reserved.
//

import Foundation
import UIKit
import MultipeerConnectivity


extension UIViewController {

    func invitationAlert(manager: MPCManager, peer: String) {
        
        // Let the user know of the invite and choose whether to accept
        let alert = UIAlertController(title: "", message: "\(peer) would like to Click with you to share photos and profiles.", preferredStyle: UIAlertControllerStyle.Alert)
        
        let acceptAction: UIAlertAction = UIAlertAction(title: "Accept", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
            // Set the handler to "true" so we connect
            manager.invitationHandler(true, manager.session)
        }
        
        let notNowAction = UIAlertAction(title: "No Thanks", style: UIAlertActionStyle.Cancel) { (UIAlertAction) -> Void in
            // The the invite handler to "false" so we don't connect
            manager.invitationHandler(false, manager.session)
        }
        
        let hideAction = UIAlertAction(title: "Hide Me From All Devices", style: UIAlertActionStyle.Destructive, handler: { (UIAlertAction) -> Void in
            // Turn off the advertising and browsing and disconnect from any sessions
            manager.serviceBrowser.stopBrowsingForPeers()
            manager.serviceAdvertiser.stopAdvertisingPeer()
            manager.session.disconnect()
        })
        
        alert.addAction(acceptAction)
        alert.addAction(notNowAction)
        alert.addAction(hideAction)
        
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            
            print("Showing Invitation Alert")
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func photoSavedAlert() {
        
        let alert = UIAlertController(title: "Saved", message: "Any received photos will be saved to your device's photo album.", preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(okAction)
        dispatch_async(dispatch_get_main_queue(), {
            
            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            
                print("Showing PhotoSaved Alert")
                self.presentViewController(alert, animated: true, completion: nil)

            }
        })
    }
    
    func noSelectedPhoto() {
        let alert = UIAlertController(title: "Slow Down Sonny!!!", message: "You need to select an image to send first before you go rushing off to the post office.", preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

