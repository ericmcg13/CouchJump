//
//  ReceivedImageViewController.swift
//  CouchJump
//
//  Created by Eric McGaughey on 11/6/15.
//  Copyright © 2015 Eric McGaughey. All rights reserved.
//

/* This viewcontroller contains all the logic for displaying and dismissing any received images from connected peers in the MPCManager class */

import UIKit


class ReceivedImageViewController: UIViewController {
    
    var receivedImageView = UIView()
    var darkWall = UIView()
    var showAlertOnce = false
    var displayedImage: UIImageView?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Add the dark opacity background that will block user interactions through it
        darkWall.backgroundColor = UIColor.blackColor()
        darkWall.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the swipe gestures to allow users to dismiss any received photos
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: "handlesSwipes:")
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: "handlesSwipes:")
        
        leftSwipe.direction = .Left
        rightSwipe.direction = .Right
        
        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
        
        // Add the darkWall and allow userInteraction thru the invisible wall until an image is displayed
        self.view.addSubview(darkWall)
        displayDarkground(false)
    }
    
    func animateSwipes(positiveOrNegativeDirection: CGFloat) {
        UIView.animateWithDuration(0.3, delay: 0.1, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
            self.displayedImage?.center.x -= self.view.bounds.width * positiveOrNegativeDirection
        }) { (finished) -> Void in
            if finished {
                self.removeImageView(self.displayedImage!)
                self.displayedImage = nil
            }
        }
    }
    
    func handlesSwipes(sender: UISwipeGestureRecognizer) {
        if sender.direction == .Left {
            print("Did swipe left")
            animateSwipes(1)
            
        }else if sender.direction == .Right {
            print("Did swipe right")
            animateSwipes(-1)
        }
    }
    
    func animateTheReceivedImage(view: UIView) {
        UIView.animateWithDuration(2.0, delay: 0.1, usingSpringWithDamping: 0.2, initialSpringVelocity: 10.0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
            self.displayedImage?.center.y = self.view.center.y
            self.displayedImage?.center.x = self.view.center.x
            }, completion: nil)
    }
    
    func removeImageView(imageView: UIView) {
        imageView.removeFromSuperview()
        displayDarkground(false)
    }
    
    func displayDarkground(state: Bool) {
        state ? (darkWall.alpha = 0.6, darkWall.userInteractionEnabled = true) : (darkWall.alpha = 0.0, darkWall.userInteractionEnabled = false)
    }
    
    func didReceiveImageFromPeer(image: UIImage) {
        
        // Here is where we will save the received image to the device
        UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            if self.displayedImage != nil {
                self.removeImageView(self.displayedImage!)
            }
            // Image is displayed so turn the darkWall on
            self.displayDarkground(true)
            
            // Set the size of the image box and make the image scale apsect to fit
            self.displayedImage = UIImageView(image: image) 
            self.displayedImage?.frame = CGRect(x: 0,
                                                y: self.view.bounds.height,
                                                width: (self.view.bounds.width - 20),
                                                height: self.view.bounds.height)
            self.displayedImage?.contentMode = .ScaleAspectFit
            
            // Set the image off screen so we can animate it to appear
            self.displayedImage?.center = self.view.center
            self.displayedImage?.center.y += self.view.bounds.height
            
            // Everything is set, create the image subview
            self.view.addSubview(self.displayedImage!)
                
            // Call the animate function
            self.animateTheReceivedImage(self.receivedImageView)
            
        })
        
        if !showAlertOnce {
            // Show the alert that the photo is being saved but only show it once
            photoSavedAlert()
            showAlertOnce = true
        }
        
    }

}
