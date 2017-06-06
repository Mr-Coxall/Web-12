//
//  ToyDisplayViewController.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-09.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import SpriteKit
import PlaygroundSupport

@objc(ToyDisplayViewController)
public class ToyDisplayViewController: SceneViewController {
    var toyScene: ToyDisplayScene
    let accessibilityDescriptionView = UIView()
    
    var inactiveAccessibilityLabel: String? {
        get {
            return nil
        }
    }
    
    var activeAccessibilityLabel: String? {
        get {
            return NSLocalizedString("SpheroSimulator_AccessibilityDescription", value: "A simulation of Sphero rolling around as you command it.", comment: "VoiceOver description of Sphero simulator.")
        }
    }
    
    var accessibilityBottomAnchor: NSLayoutYAxisAnchor {
        get {
            return liveViewSafeAreaGuide.bottomAnchor
        }
    }
    
    public init() {
        toyScene = ToyDisplayScene()
        super.init(scene: toyScene)
        toyScene.safeFrameContainer = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        toyScene = ToyDisplayScene()
        
        super.init(coder: aDecoder)
        
        self.scene = toyScene
        toyScene.safeFrameContainer = self
    }
       
    public override func didReceiveRollMessage(heading: Double, speed: Double) {
        toyScene.roll(heading: heading, speed: speed)
    }
    
    public override func didReceiveSetMainLedMessage(color: UIColor) {
        toyScene.setColor(color)
    }
    
    public override func liveViewMessageConnectionOpened() {
        super.liveViewMessageConnectionOpened()
        
        toyScene.reset()
        
        accessibilityDescriptionView.accessibilityHint = activeAccessibilityLabel
        accessibilityDescriptionView.isAccessibilityElement = activeAccessibilityLabel != nil
    }
    
    public override func liveViewMessageConnectionClosed() {
        super.liveViewMessageConnectionClosed()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        toyScene.backgroundColor = view.backgroundColor ?? .white
        
        view.insertSubview(accessibilityDescriptionView, aboveSubview: spriteView)
        accessibilityDescriptionView.accessibilityHint = inactiveAccessibilityLabel
        accessibilityDescriptionView.isAccessibilityElement = inactiveAccessibilityLabel != nil
        accessibilityDescriptionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            accessibilityDescriptionView.leadingAnchor.constraint(equalTo: liveViewSafeAreaGuide.leadingAnchor, constant: 20.0),
            accessibilityDescriptionView.trailingAnchor.constraint(equalTo: liveViewSafeAreaGuide.trailingAnchor, constant: -20.0),
            accessibilityDescriptionView.topAnchor.constraint(equalTo: liveViewSafeAreaGuide.topAnchor, constant: 20.0),
            accessibilityDescriptionView.bottomAnchor.constraint(equalTo: accessibilityBottomAnchor, constant: -20.0)
        ])
    }
}
