//
//  AppDelegate.swift
//  CouchJump
//
//  Created by Eric McGaughey on 9/14/15.
//  Copyright © 2015 Eric McGaughey. All rights reserved.
//

import UIKit
import Fabric
import TwitterKit
import Foundation
import WebKit
import QuartzCore
import FBSDKCoreKit



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UIWebViewDelegate, WKNavigationDelegate {

    var window: UIWindow?
    var CouchJumpingUserAgent: NSString = ""
    let couchJumpingUA = "couchjumping/0.0.1"


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        
        // Make a blank WKwebview and check for navigator.userAgent
        let webView = UIWebView()
        
        let currentUserAgent: NSString = webView.stringByEvaluatingJavaScriptFromString("navigator.userAgent")!
        
            // Split the string in half from first space
            let colonRange: NSRange = (currentUserAgent).rangeOfString(" ")
            if (colonRange.location != NSNotFound) {
                let secondHalf: NSString = currentUserAgent.substringFromIndex(NSMaxRange(colonRange))
                // Replace the first half with couchjumping and save
                self.CouchJumpingUserAgent = NSString(format: "%@ %@", self.couchJumpingUA,secondHalf)
                print(self.CouchJumpingUserAgent)
            }else {
                // Failer
                self.CouchJumpingUserAgent = self.couchJumpingUA
                // TODO: Failer
        }
        
        
        // Set the user agent for the device
        let userAgent = NSUserDefaults.standardUserDefaults()
        userAgent.setObject(self.CouchJumpingUserAgent, forKey: "UserAgent")
        userAgent.registerDefaults(["UserAgent" : CouchJumpingUserAgent])
        
        Twitter.sharedInstance().startWithConsumerKey("TWITTER-KEY", consumerSecret: "TWITTER-SECRET")
        Fabric.with([Twitter.self])
                
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

