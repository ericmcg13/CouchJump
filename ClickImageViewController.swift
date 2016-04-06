//
//  ClickImageViewController.swift
//  CouchJump
//
//  Created by Eric McGaughey on 10/20/15.
//  Copyright © 2015 Eric McGaughey. All rights reserved.
//

import UIKit
import QuartzCore
import MultipeerConnectivity


class ClickImageViewController: ReceivedImageViewController, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    private var imageData: NSData?
    private lazy var mpcManager = MPCManager()
    private let imagePicker = UIImagePickerController()
    private let activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var selectImageBtn: UIButton!
    @IBOutlet weak var sendBtn: UIButton!
    @IBOutlet weak var userListTblv: UITableView!
    @IBOutlet weak var closeXBTN: UIButton!
    
    private func enableView(state: Bool) {
        userListTblv.userInteractionEnabled = state
        selectImageBtn.userInteractionEnabled = state
        sendBtn.userInteractionEnabled = state
    }
    
    private func enableSendBtn(state: Bool) {
        state ? (sendBtn.enabled = true, sendBtn.layer.opacity = 1.0 ) : (sendBtn.enabled = false, sendBtn.layer.opacity = 0.5)
    }
    
    private func buttonShadow(button: UIButton) {
        button.layer.shadowOffset = CGSizeMake(5.0, 5.0)
        button.layer.shadowRadius = 5
        button.layer.shadowColor = UIColor.grayColor().CGColor
        button.layer.shadowOpacity = 1.0
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        userListTblv.delegate = self
        userListTblv.dataSource = self
        
        // Add shadows to the buttons to keep style consistency
        buttonShadow(selectImageBtn)
        buttonShadow(sendBtn)
        buttonShadow(closeXBTN)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set delegates
        mpcManager.delegate = self
        imagePicker.delegate = self
        
        // View is loaded so start browsing / advertising for peers
        self.mpcManager.serviceAdvertiser.startAdvertisingPeer()
        self.mpcManager.serviceBrowser.startBrowsingForPeers()
        
        // Disable the send button as we are not connected to any peers
        enableSendBtn(false)
        
    }
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func closeVCAction(sender: AnyObject) {
        
        // Sorry, we're closing. Stop advertising / browsing for customers
        self.mpcManager.serviceAdvertiser.stopAdvertisingPeer()
        self.mpcManager.serviceBrowser.stopBrowsingForPeers()
        
        // Shop is closed so kick everyone out
        self.mpcManager.session.disconnect()
        self.mpcManager.foundPeers.removeAll()
        
        delay(0.2) { () -> () in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func selectImageAction(sender: UIButton) {
        
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .PhotoLibrary
        self.userListTblv.reloadData()
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func sendBtnAction(sender: UIButton) {
        
        if imageData != nil {
            
            // Start the progressHUD to show the user shits happen'n
            let progressHUD = ProgressHUD(text: "Sending")
            self.view.addSubview(progressHUD)
            
            // Put the image in a background queue and send it
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), { () -> Void in
                self.enableView(false)
                self.mpcManager.sendClickData(self.imageData!)
                
                // Get the main queue ready to hide the progressHUD once the image has finished sending
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.enableView(true)
                    progressHUD.hide()
                })
            })
        }else {
            // Image is nil so display the "no photo" alert
            self.noSelectedPhoto()
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = self.userListTblv.dequeueReusableCellWithIdentifier("ClickUserName") as UITableViewCell!
        
        // If view is disabled? Leave it disabled? or make in enabled?
        // TODO: someone could appear in tableview while sending. The following is a bad idea:
        // Changes in the tableview so kill any animation and enable anything that may have been diabled.
        activityView.stopAnimating()
        enableView(true)

        // Get rid of any accessories
        cell?.accessoryView = .None
        cell.accessoryType = .None
        
        let friend = self.mpcManager.foundPeers[indexPath.row]
        
        // Go through the foundpeers array to check for connected peers
        for (_, aPeer) in (mpcManager.session.connectedPeers.enumerate()) {
            
            if friend == aPeer {
                
                // Show a checkmark to let the user know of connection
                cell.accessoryType = .Checkmark
                
                // And enable the send button
                enableSendBtn(true)
            }
        }
        
        cell.textLabel?.text = friend.displayName
        
        // Customize cell
        cell!.textLabel?.textColor = UIColor(red: 32/255, green: 177/255, blue: 154/255, alpha: 1.0)
        cell!.textLabel?.font = UIFont(name: "futura", size: 20)
        cell!.textLabel?.textAlignment = .Center
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)

        if cell?.selected == true {
            
            if cell?.accessoryType == .Checkmark {
                
                // If the cell already has a checkmark, we need ask whether the user wishes to disconnect
                let alert = UIAlertController(title: "Disconnect?", message: "Do you wish to disconnect from \((cell?.textLabel?.text)!)?", preferredStyle: UIAlertControllerStyle.Alert)
                // Yes = disconnect
                let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.Destructive, handler: { (UIAlertAction) -> Void in
                    self.mpcManager.session.disconnect()
                    cell?.accessoryType = .None
                })
                // No = dismiss alert, it was an accident
                let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.Default, handler: nil)
                alert.addAction(yesAction)
                alert.addAction(noAction)
                self.presentViewController(alert, animated: true, completion: nil)
        
            }else {
                
                // Otherwise, we need to start the activity indicator
                activityView.startAnimating()
                cell?.accessoryView = activityView
                
                // If its running...
                if activityView.isAnimating() == true {
                    // Trying to connect to peer, so disable user input
                    enableView(false)
                }
                
                // and start the connection
                let selectedPeer = mpcManager.foundPeers[indexPath.row]
                self.mpcManager.serviceBrowser.invitePeer(selectedPeer, toSession: self.mpcManager.session, withContext: nil, timeout: 20)
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mpcManager.foundPeers.count
    }
    
    func animateTable() {
        userListTblv.reloadData()
        let cells = userListTblv.visibleCells
        let tableHeight: CGFloat = userListTblv.bounds.size.height
        
        for i in cells {
            let cell: UITableViewCell = i
            cell.transform = CGAffineTransformMakeTranslation(0, tableHeight)
        }
        var index = 0
        
        for a in cells {
            let cell: UITableViewCell = a
            UIView.animateWithDuration(1.5, delay: 0.05 * Double(index), usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [], animations: {
                cell.transform = CGAffineTransformMakeTranslation(0, 0);
                }, completion: nil)

            index += 1
        }
    }
    
}

extension ClickImageViewController : UIImagePickerControllerDelegate {
    
    // MARK: Image picking functions
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            imageData = UIImageJPEGRepresentation(pickedImage, 0.5)
            imagePreview.image = pickedImage
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}

extension ClickImageViewController : MPCManagerDelegate {
    
    func connectedDevices(manager: MPCManager, connectedDevices: [String]) {
        print(connectedDevices)
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            
            // Lets disable the send button, we can enable it if need be when we check for connected peers
            if connectedDevices.isEmpty == true {
                self.enableSendBtn(false)
            }
            self.userListTblv.reloadData()
        }
    }
    
    func profileInfoReceived(manager: MPCManager, profileString: String) {
       // Nothing to do without a webview
    }
    
    func imageReceived(manager: MPCManager, image: UIImage) {
        self.didReceiveImageFromPeer(image)
    }
    
    func invitationWasReceived(fromPeer: String) {
        invitationAlert(mpcManager, peer: fromPeer)
    }
    
    func connectedWithPeer(peerID: String) { }
    
    func foundPeer() {
        print("Found peer so reloading the table")
        animateTable()
    }
    
    func lostPeer() {
        print("Lost peer so reloading the table")
        animateTable()
    }
    
}









