//
//  MPCManager.swift
//  CouchJump
//
//  Created by Eric McGaughey on 10/1/15.
//  Copyright © 2015 Eric McGaughey. All rights reserved.
//

import Foundation
import MultipeerConnectivity


protocol MPCManagerDelegate {
    func connectedDevices(manager: MPCManager, connectedDevices: [String])
    func profileInfoReceived(manager: MPCManager, profileString: String)
    func imageReceived(manager: MPCManager, image: UIImage)
    func invitationWasReceived(fromPeer: String)
    func connectedWithPeer(peerID: String)
    func foundPeer()
    func lostPeer()
}


class MPCManager: NSObject {
    private let serviceType = "couch-jumping"
    private let myPeerId = MCPeerID(displayName: UIDevice.currentDevice().name)
    
    let serviceAdvertiser: MCNearbyServiceAdvertiser
    let serviceBrowser: MCNearbyServiceBrowser
    
    var delegate: MPCManagerDelegate?
    var invitationHandler: ((Bool, MCSession)->Void)!
    var foundPeers = [MCPeerID]()

    
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceBrowser.delegate = self
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    lazy var session: MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.Required)
        session.delegate = self
        
        return session
    }()
    // Create a function to send click data
    func sendClickData(data: NSData) {
        if session.connectedPeers.count > 0 {
            do {
                try self.session.sendData(data, toPeers: session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
                print(data)
            } catch let error as NSError {
                print(error)
            }
        }
    }
}

extension MPCManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        print("didNotStartAdvertising")
        
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        print("didReceiveInvitationFromPeer")
        self.invitationHandler = invitationHandler
        
        delegate?.invitationWasReceived(peerID.displayName)
    }
}

extension MPCManager: MCNearbyServiceBrowserDelegate {
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        print("didNotStartBrowsingForPeers")
    }
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer: \(peerID.displayName)")
        
        foundPeers.append(peerID)
        delegate?.foundPeer()
    }
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")
        
        for (index, aPeer) in (foundPeers.enumerate()){
            if aPeer == peerID {
                foundPeers.removeAtIndex(index)
                break
            }
        }
        delegate?.lostPeer()
    }
}

extension MCSessionState {
    
    func stringValue() -> String {
        switch(self) {
        case .Connecting: return "Connecting..."
        case .Connected: return "Connected!!!"
        case .NotConnected: return "Not Connected"
        }
    }
}

extension MPCManager: MCSessionDelegate {
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        print("didReceiveData: \(data.length) bytes")
        
        // If the data is an NSString, its the 'click' profile
        if let sessionString = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
            self.delegate?.profileInfoReceived(self, profileString: sessionString)
            print(sessionString)
        }else {
            
        // else if the data is an image, its the 'click' image
            if let sessionImage = UIImage(data: data) {
                self.delegate?.imageReceived(self, image: sessionImage)
                print(sessionImage)
            }
        }
    }
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        print("Peer \(peerID.displayName) didChangeState: \(state.stringValue())")
        self.delegate?.connectedDevices(self, connectedDevices: session.connectedPeers.map({$0.displayName}))
        
        if state == .Connected {
            delegate?.connectedWithPeer(peerID.displayName)
        }
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {}
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {}

}


