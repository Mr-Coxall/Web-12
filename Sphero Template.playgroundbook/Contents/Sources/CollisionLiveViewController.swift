//
//  CollisionLiveViewController.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-27.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit

@objc(CollisionLiveViewController)
public class CollisionLiveViewController: ToyDisplayViewController {
    
    @IBOutlet weak var collisionSensorView: SensorDisplayView!
    @IBOutlet weak var collisionExclamationMarkImageView: UIImageView!
    @IBOutlet weak var spheroImageView: UIImageView!
    @IBOutlet weak var wallImageView: UIImageView!
    @IBOutlet weak var speedLinesImageView: UIImageView!
    @IBOutlet weak var collisionAccessibilityContainer: UIView!
    
    private var bottomSensorViewConstraint: NSLayoutConstraint?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        toyScene.setOriginDotColor(UIColor(red: 251.0/255.0, green: 216.0/255.0, blue: 93.0/255.0, alpha: 1.0))
        
        let bottomSensorConstraint = collisionSensorView.bottomAnchor.constraint(equalTo: liveViewSafeAreaGuide.bottomAnchor, constant: -30.0)
        NSLayoutConstraint.activate([
            bottomSensorConstraint
            ])
        
        bottomSensorViewConstraint = bottomSensorConstraint
        
        updateImpactAcceleration(0.0)
        
        let impactAccelText = NSLocalizedString("collision.sensorDisplay.titleText", value: "Impact Acceleration", comment: "collision sensor value, Impact Acceleration is how many 'g's the accelerometer measured when Sphero ran into a wall")
        collisionSensorView.titleLabel.text = impactAccelText.uppercased()
        collisionAccessibilityContainer.accessibilityLabel = NSLocalizedString("collision.accessibilityContainer.accessibilityLabel", value: "Sphero colliding against a wall with an exclaimation mark above it's head and speed lines trailing behind it.", comment: "collision image accessibility")
    }
    
    public override func updateViewConstraints() {
        if isVeryCompact() {
            collisionSensorView.preferredSize = .compact
            bottomSensorViewConstraint?.constant = 0.0
        } else {
            collisionSensorView.preferredSize = .expanded
            bottomSensorViewConstraint?.constant = -30.0
        }
        
        super.updateViewConstraints()
    }
    
    
    public override func liveViewMessageConnectionOpened() {
        super.liveViewMessageConnectionOpened()
        
        updateImpactAcceleration(0.0)
    }
    
    public override func didReceiveCollision(data: CollisionData) {
        super.didReceiveCollision(data: data)
        
        let x = data.impactAcceleration.x
        let y = data.impactAcceleration.y
        updateImpactAcceleration(hypot(x,y))
        
        toyScene.showCollision(data: data)
    }

    private func updateImpactAcceleration(_ total: Double) {
        collisionSensorView.accessibilityLabel = String(format: NSLocalizedString("collision.sensorView.accessbilityLabel", value: "Impact Acceleration. %.1f g-forces", comment: "collision impact acceleration sensor display accessibility label, %.1f g-forces is how hard the robot collided with the wall, in 'g's, ie 1.8g"), total)
        collisionSensorView.sensorValueLabel.text = String(format: NSLocalizedString("collision.sensorView.sensorValue", value: "%.1f g", comment: "collision impact acceleration sensor display, %.1fg is how hard the robot collided with the wall, in 'g's, ie 1.8g"), total)
    }
    
    public override var liveViewSafeAreaFrame: CGRect {
        get {
            var safeFrame = super.liveViewSafeAreaFrame
            
            if collisionSensorView.frame.minY < safeFrame.maxY {
                safeFrame.size.height = collisionSensorView.frame.minY - safeFrame.minY
            }
            
            return safeFrame
        }
    }
    
    override var accessibilityBottomAnchor: NSLayoutYAxisAnchor {
        get {
            return collisionSensorView.topAnchor
        }
    }
    
}
