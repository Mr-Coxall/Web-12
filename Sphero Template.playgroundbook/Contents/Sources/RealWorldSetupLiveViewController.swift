//
//  RealWorldSetupLiveViewController.swift
//  spheroArcade
//
//  Created by Jeff Payan on 2017-03-31.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit
import SpriteKit

@objc(RealWorldSetupLineView)
public class RealWorldSetupLineView: UIView {
    
    private var dashedLine: CAShapeLayer?
    
    public override func layoutSubviews() {
        dashedLine?.removeFromSuperlayer()
        dashedLine = nil
        
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        let lineFrame = bounds
        linePath.move(to: CGPoint(x: lineFrame.midX, y: lineFrame.minY))
        linePath.addLine(to: CGPoint(x: lineFrame.midX, y: lineFrame.maxY))
        line.path = linePath.cgPath
        line.strokeColor = UIColor.white.cgColor
        line.lineWidth = 3.5
        line.lineJoin = kCALineJoinRound
        line.lineDashPattern = [10, 10]
        layer.addSublayer(line)
        dashedLine = line
    }
}

@objc(RealWorldSetupLiveViewController)
public class RealWorldSetupLiveViewController: ToyDisplayViewController {
    
    @IBOutlet weak var dotStartView: UIView!
    
    @IBOutlet weak var topRulerConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomRulerConstraint: NSLayoutConstraint!
    @IBOutlet weak var topRulerImageView: UIImageView!
    @IBOutlet weak var bottomRulerImageView: UIImageView!
    @IBOutlet weak var topShoesImageView: UIImageView!
    @IBOutlet weak var bottomShoesImageView: UIImageView!
    @IBOutlet weak var realWorldAccessibilityContainer: UIView!
    
    @IBOutlet weak var distanceTravelledSensorView: SensorDisplayView!
    
    private var bottomSensorViewConstraint: NSLayoutConstraint?
    
    var dashedLine: CAShapeLayer?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if let dotColor = dotStartView.backgroundColor {
            toyScene.setOriginDotColor(dotColor)
        }
        
        realWorldAccessibilityContainer.accessibilityLabel = NSLocalizedString("realWorld.accessibilityContainer.accessibilityLabel", value: "Sphero is rolling from Player 1's shoes to Player 2's shoes, leaving a trail behind it.", comment: "real world setup accessibility, describes a dashed path going from a pair of shoes to another pair of shoes, indicating a path the Sphero will roll.")
        
        topRulerImageView.accessibilityLabel = NSLocalizedString("realWorld.topRuler.accessibility", value: "A piece of Sphero maze tape, indicating the top bounds of Sphero Pong.", comment: "real world setup image accessibility, image is a piece of tape used to mark where player 2 should stand.")
        bottomRulerImageView.accessibilityLabel = NSLocalizedString("realWorld.bottomRuler.accessibility", value: "A piece of Sphero maze tape, indicating the bottom bounds of Sphero Pong.", comment: "real world setup image accessibility, image is a piece of tape used to mark where player 1 should stand.")
        
        topShoesImageView.accessibilityLabel = NSLocalizedString("realWorld.topShoes.accessibility", value: "Player 2's red shoes standing behind the top piece of maze tape.", comment: "real world setup image accessibility, image is a pair of red shoes.")
        bottomShoesImageView.accessibilityLabel = NSLocalizedString("realWorld.bottomShoes.accessibility", value: "Player 1's blue shoes standing behind the bottom piece of maze tape.", comment: "real world setup image accessibility, image is a pair of blue shoes.")
        distanceTravelledSensorView.titleLabel.text = NSLocalizedString("realWorldSetup.sensorView.titleLabel.text", value: "Distance Travelled", comment: "real world setup, sensor view header label, tracks sphero's distance")
        distanceTravelledSensorView.isAccessibilityElement = true
        
        let bottomSensorConstraint = distanceTravelledSensorView.bottomAnchor.constraint(equalTo: liveViewSafeAreaGuide.bottomAnchor, constant: -30.0)
        NSLayoutConstraint.activate([
            bottomSensorConstraint
            ])
        
        bottomSensorViewConstraint = bottomSensorConstraint
        updateDistanceTravelled(0.0)
    }
    
    public override func updateViewConstraints() {
        if isVerticallyCompact() {
            topRulerConstraint.constant = 0.0
            bottomRulerConstraint.constant = 50.0
        } else {
            topRulerConstraint.constant = 70.0
            bottomRulerConstraint.constant = 90.0
        }
        
        if isVeryCompact() {
            distanceTravelledSensorView.preferredSize = .compact
            bottomSensorViewConstraint?.constant = 0.0
        } else {
            distanceTravelledSensorView.preferredSize = .expanded
            bottomSensorViewConstraint?.constant = -20.0
        }
        
        super.updateViewConstraints()
    }
    
    public override func didReceiveSensorData(_ data: SensorData) {
        super.didReceiveSensorData(data)
        updateDistanceTravelled(abs(data.locator?.position?.y ?? 0.0))
    }
    
    public override func liveViewMessageConnectionOpened() {
        super.liveViewMessageConnectionOpened()
        updateDistanceTravelled(0.0)
    }
    
    private func updateDistanceTravelled(_ total: Double) {
        distanceTravelledSensorView.accessibilityLabel = String(format: NSLocalizedString("realWorldSetup.sensorView.accessibility", value: "Distance Travelled. %.1f centimeters", comment: "real world page accessibility for sensor view. %.1f is how far Sphero has travelled this run of the program in centimeters, example string: 153.5 cm"), total)
        distanceTravelledSensorView.sensorValueLabel.text = String(format: NSLocalizedString("realWorldSetup.sensorView.sensorValue", value: "%.1f cm", comment: "how far Sphero has travelled this run of the program in centimeters, example string: 153.5 cm"), total)
    }
    
    public override var liveViewSafeAreaFrame: CGRect {
        get {
            var safeFrame = super.liveViewSafeAreaFrame
            
            if distanceTravelledSensorView.frame.minY < safeFrame.maxY {
                safeFrame.size.height = distanceTravelledSensorView.frame.minY - safeFrame.minY
            }
            
            return safeFrame
        }
    }
}
