//
//  Utilities.swift
//  CouchJump
//
//  Created by Eric McGaughey on 10/21/15.
//  Copyright © 2015 Eric McGaughey. All rights reserved.
//

import Foundation
import UIKit


/* TODO: Darken the Background of the progressHUD to make it more visible on the clickimageVC background. Maybe disable any view behind the progressHUD */

class ProgressHUD: UIVisualEffectView {
    
    private var text: String? {
        didSet {
            label.text = text
        }
    }
    private let activityIndictor: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    private let label: UILabel = UILabel()
    private let blurEffect = UIBlurEffect(style: .Light)
    private let vibrancyView: UIVisualEffectView
//    let backGroundColor = UIColor(red: 32/255, green: 177/255, blue: 154/255, alpha: 1.0).CGColor
    let backGroundColor = UIColor.grayColor().CGColor
    
    init(text: String) {
        self.text = text
        self.vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(forBlurEffect: blurEffect))
        super.init(effect: blurEffect)
        self.setup()
    }
    
    required init(coder aDecoder: NSCoder) {
        self.text = ""
        self.vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(forBlurEffect: blurEffect))
        super.init(coder: aDecoder)!
        self.setup()
        
    }
    
    func setup() {
        contentView.addSubview(vibrancyView)
        vibrancyView.contentView.addSubview(activityIndictor)
        vibrancyView.contentView.addSubview(label)
        activityIndictor.startAnimating()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if let superview = self.superview {
            
            let width = superview.frame.size.width / 2.3
            let height: CGFloat = 50.0
            self.frame = CGRectMake(superview.frame.size.width / 2 - width / 2,
                superview.frame.height / 2 - height / 2,
                width,
                height)
            vibrancyView.frame = self.bounds
            
            let activityIndicatorSize: CGFloat = 40
            activityIndictor.frame = CGRectMake(5, height / 2 - activityIndicatorSize / 2,
                activityIndicatorSize,
                activityIndicatorSize)
            
            layer.cornerRadius = 8.0
            layer.masksToBounds = true
            layer.backgroundColor = backGroundColor
            label.text = text
            label.textAlignment = NSTextAlignment.Center
            label.frame = CGRectMake(activityIndicatorSize + 5, 0, width - activityIndicatorSize - 15, height)
            label.textColor = UIColor.blackColor()
            label.font = UIFont.boldSystemFontOfSize(16)
        }
    }
    
    func show() {
        self.hidden = false
    }
    
    func hide() {
        self.hidden = true
    }
}
