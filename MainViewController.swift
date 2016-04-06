//
//  MainViewController.swift
//  CouchJump
//
//  Created by Eric McGaughey on 9/14/15.
//  Copyright © 2015 Eric McGaughey. All rights reserved.
//

// Client.log.in
// Client.log.out


import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import TwitterKit
import Fabric
import WebKit
import MultipeerConnectivity


class MainViewController: ReceivedImageViewController, UIWebViewDelegate, WKNavigationDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private lazy var bleManager = BLEManager()
    private lazy var mpcManager = MPCManager()
    private var webView: WKWebView!
    
    private struct Click {
        
        static let request = "clickrequest"
        static let confirm = "displayconfirm"
        static let accepted = "clickaccepted"
        static let rejected = "clickrejected"
        static let found = "clickuserfound"
    }
    
    override func loadView() {
        
        // Setup the wkwebview and load the couchjumping site
        self.webView = WKWebView()
        self.webView.navigationDelegate = self
        self.view = self.webView
        let url = NSURL(string: "http://WEB-ADRESS-HERE")
        webView.loadRequest(NSURLRequest(URL: url!))
        
        // TODO: Something like this after the user logs in OR when the click is fired up
        self.webView.evaluateJavaScript("Client.get('user')") { (result, error1) -> Void in
            
            if error1 == nil {
                
                if result != nil {
                    
                    self.bleManager.userObject = result as! String

                }

            }

        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the delegates
        mpcManager.delegate = self
        
        // TODO: do this after log in {{ App is open so listen out for MPC Click connections
        self.mpcManager.serviceAdvertiser.startAdvertisingPeer()
        self.mpcManager.serviceBrowser.startBrowsingForPeers()
        
    }
    
    func javaScriptErrorReporting(message: String) {
        // TODO: finish working on this to pass correct errors THROW / TRY
        webView.evaluateJavaScript("report.error(\(message))", completionHandler: nil)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showClickPhoto" {
            
            self.mpcManager.session.disconnect()
            self.mpcManager.foundPeers.removeAll()
            
            self.mpcManager.serviceAdvertiser.stopAdvertisingPeer()
            self.mpcManager.serviceBrowser.stopBrowsingForPeers()
        }
    }
    
    // MARK: WKWebView Functions
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        
        let request: NSURLRequest = navigationAction.request
        
        if (request.URL!.scheme == "inapp") {
            // MARK: Click profile activation
            
            // Step 1: Let listening devices know that I need their profile info for display
            switch (request.URL!.host)! {
                
                case "click-photo":
                    self.performSegueWithIdentifier("showClickPhoto", sender: nil)
                
                case "click-profile":
                    print("Step 1: send the request trigger")
                    self.mpcManager.sendClickData(Click.request.dataUsingEncoding(NSUTF8StringEncoding)!)
                
                case "click-with":
                    print("Step 4: send my user object string to display on other device")
                    self.webView.evaluateJavaScript("Client.getUserString()", completionHandler: { (result, error1) -> Void in
                        
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                            let convertedString = (Click.confirm + (result as! String)).dataUsingEncoding(NSUTF8StringEncoding)!
                            self.mpcManager.sendClickData(convertedString)
                        })
                    })
                
                case "click-confirm":
                    print("Step 5: send confirmed notification")
                    self.mpcManager.sendClickData(Click.accepted.dataUsingEncoding(NSUTF8StringEncoding)!)
                
                case "click-reject":
                    print("Step 5: send the rejection notification")
                    self.mpcManager.sendClickData(Click.rejected.dataUsingEncoding(NSUTF8StringEncoding)!)
                
                case "login-facebook":
                    let fbLoginManager = FBSDKLoginManager()
                    fbLoginManager.loginBehavior = FBSDKLoginBehavior.Native
                    fbLoginManager.logInWithReadPermissions(["public_profile", "email", "user_friends", "token", "id"], fromViewController: self, handler: { (result, error) -> Void in
                        if error == nil {
                            // TODO: Success / ERROR HANDLING
                            self.getFBUserData()
                            print("\(result)")
                        }
                    })
                case "login-twitter":
                    Twitter.sharedInstance().logInWithCompletion({ (session, error) -> Void in
                        if session != nil {
                            
                            self.loginUserWithJSON(session!.userName, id: session!.userID, token: session!.authToken, secret: session!.authTokenSecret, network: "twitter")
                        }
                    })
                case "reload-view":
                    self.webView.reload()
                
            default:
                print("Unsupported URL host request")
                break
            }
        }
        decisionHandler(WKNavigationActionPolicy.Allow)

    }
    
    func loginUserWithJSON(name: String, id: String, token: String, secret: String?, network: String) {
        if network == "twitter" {
            // TODO: Error handling?
            let twitJSON = ("'{\"Name\":\"\(name)\",\"ID\":\"\(id)\",\"Token\":\"\(token)\",\"Secret\":\"\(secret)\"}'")
            let twitFunction = "Client.log.in(\(network), \(twitJSON));"
            self.webView.evaluateJavaScript(twitFunction, completionHandler: nil)
            
        }else if network == "facebook" {
            // TODO: Error handling?
            let fbJSON = ("'{\"Name\":\"\(name)\",\"ID\":\"\(id)\",\"Token\":\"\(token)\"}'")
            let fbFunction = "Client.log.in(\(network), \(fbJSON));"
            self.webView.evaluateJavaScript(fbFunction, completionHandler: nil)
            
        }
    }

    func getFBUserData() {
        if((FBSDKAccessToken.currentAccessToken()) != nil){
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name"]).startWithCompletionHandler({ (connection, result, error) -> Void in
                if (result != nil){
                    // Set the user information to be passed into the JSON
                    let userData = result as! NSDictionary
                    self.loginUserWithJSON(userData.objectForKey("name") as! String, id: userData.objectForKey("id") as! String, token: FBSDKAccessToken.currentAccessToken().tokenString, secret: nil, network: "facebook")
                    
                }
            })
        }
    }
}

extension MainViewController: MPCManagerDelegate {
    
    // MARK: MPC delegate methods
    func connectedDevices(manager: MPCManager, connectedDevices: [String]) {
        
        print("Connected with \(connectedDevices)")
        
    }
    
    func imageReceived(manager: MPCManager, image: UIImage) {
        
        self.didReceiveImageFromPeer(image)
        
    }
    
    func profileInfoReceived(manager: MPCManager, profileString: String) {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            
            func prefixString(prefix: String) {
                
                if profileString.hasPrefix(prefix) {
                    
                    switch (prefix) {
                
                    case Click.request:
                        // Click has been requested, send my user object for evaluation
                        print("Step 2")
                        self.webView.evaluateJavaScript("Client.get('user')", completionHandler: { (result, error1) -> Void in
                            if result != nil {
                                print("\(result)")
                                let convertedResult = (Click.found + (result as! String)).dataUsingEncoding(NSUTF8StringEncoding)
                                self.mpcManager.sendClickData(convertedResult!)
                            }else {
                                // TODO: Log error thru javascript
                                print(error1)
                            }
                        })
                        
                    case Click.found:
                        // Take the received profile and plug it into the JS tableview
                        let minusPrefix = profileString.stringByReplacingOccurrencesOfString(Click.found, withString: "")
                        self.webView.evaluateJavaScript("Client.click.user.found(\(minusPrefix))", completionHandler: nil)
                        
                    case Click.confirm:
                        // User selected from the table view so send my user profile for display on the receiver
                        let minusPrefix = profileString.stringByReplacingOccurrencesOfString(Click.confirm, withString: "")
                        self.webView.evaluateJavaScript("Client.click.user.confirm(\(minusPrefix))", completionHandler: nil)
                        
                    case Click.rejected:
                        // Click has been rejected so tell the webview
                        self.webView.evaluateJavaScript("Client.click.user.confirmed(false)", completionHandler: nil)
                        
                    case Click.accepted:
                        //Click has been accepted so tell the webview
                        self.webView.evaluateJavaScript("Client.click.user.confirmed(true)", completionHandler: nil)
                        
                    default:
                        break
                        
                    }
                }
            }
        }
    }
    
    func invitationWasReceived(fromPeer: String) {
        invitationAlert(mpcManager, peer: fromPeer)
    }
    
    func foundPeer() {
        for peer in mpcManager.foundPeers {
            self.mpcManager.serviceBrowser.invitePeer(peer, toSession: self.mpcManager.session, withContext: nil, timeout: 30)
        }
    
    }
    
    func lostPeer() { }
    
    func connectedWithPeer(peerID: String) { }
}
