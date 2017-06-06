//
//  AimLiveViewController.swift
//  spheroArcade
//
//  Created by Jeff Payan on 2017-03-22.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit
import SpriteKit

@objc(AimLiveViewController)
public class AimLiveViewController: ToyDisplayViewController {
    
    private let directionNode = SKSpriteNode(imageNamed: "aim-lines")
    
    private var currentHeading: Double = 0.0
    
    private var didShowRotation = false
    
    override var inactiveAccessibilityLabel: String? {
        get {
            return NSLocalizedString("aim.accessibilityContainer.description", value: "Sphero sitting in front of a pair of blue shoes. A dashed-line indicating Sphero should roll forward, turn around, and roll back.", comment: "VoiceOver description of Aim page before code is run. Image is of blue shoes and Sphero tracing out roll forward, roll backward.")
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        toyScene.setOriginDotColor(UIColor(red: 184.0/255.0, green: 233.0/255.0, blue: 134.0/255.0, alpha: 1.0))
        
        let shoesNode = SKSpriteNode(imageNamed: "aim-shoes")
        shoesNode.position.y = -85.0
        shoesNode.zPosition = -1.0
        toyScene.addExtraNode(shoesNode)
        
        directionNode.position.y = 180.0
        directionNode.zPosition = -1.0
        toyScene.addExtraNode(directionNode)
    }

    public override func liveViewMessageConnectionOpened() {
        super.liveViewMessageConnectionOpened()
        
        directionNode.run(.fadeAlpha(to: 0.0, duration: 0.5))
    }
    
    public override func liveViewMessageConnectionClosed() {
        super.liveViewMessageConnectionClosed()
        
        currentHeading = 0.0
        didShowRotation = false
    }
    
    public override func didReceiveRollMessage(heading: Double, speed: Double) {
        super.didReceiveRollMessage(heading: heading, speed: speed)
        
        if heading != currentHeading && !didShowRotation {
            didShowRotation = true
            toyScene.showRotation()
        }
        
        currentHeading = heading
    }
}
