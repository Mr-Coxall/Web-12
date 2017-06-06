//
//  HeadingLiveViewController.swift
//  spheroArcade
//
//  Created by Jeff Payan on 2017-04-03.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit

@objc(HeadingLiveViewController)
public class HeadingLiveViewController: ToyDisplayViewController {
    
    @IBOutlet weak var sensorStackView: UIStackView!
    @IBOutlet weak var headingSensorView: SensorDisplayView!
    @IBOutlet weak var velocitySensorView: SensorDisplayView!
    @IBOutlet weak var headingBoxImageView: UIImageView!
    @IBOutlet weak var headingAccessibilityContainerView: UIView!
    @IBOutlet weak var headingSpheroImageView: UIImageView!
    
    private var bottomSensorViewConstraint: NSLayoutConstraint?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        toyScene.setOriginDotColor(UIColor(red: 231.0/255.0, green: 88.0/255.0, blue: 60.0/255.0, alpha: 1.0))
        
        let bottomSensorConstraint = headingSensorView.bottomAnchor.constraint(equalTo: liveViewSafeAreaGuide.bottomAnchor, constant: -30.0)
        
        NSLayoutConstraint.activate([
            bottomSensorConstraint
            ])
        
        bottomSensorViewConstraint = bottomSensorConstraint
        
        headingAccessibilityContainerView.accessibilityLabel = NSLocalizedString("heading.accessibilityContainer.accessibilityLabel", value: "Sphero sitting on a corner of a dashed-line square with counter-clockwise arrows indicating the direction Sphero should roll.", comment: "heading image accessibility, image is a Sphero sitting on the corner of the dashed line square")
        
        let headingTitle = NSLocalizedString("heading.headingSensor.titleLabel", value: "Heading", comment: "heading sensor title, heading is the direction Sphero is rolling")
        headingSensorView.titleLabel.text = headingTitle.uppercased()
        
        let velocityTitle = NSLocalizedString("heading.velocitySensor.titleLabel", value: "Velocity", comment: "velocity sensor title, velocity is how fast Sphero is rolling")
        velocitySensorView.titleLabel.text = velocityTitle.uppercased()
        
        headingSensorView.isAccessibilityElement = true
        velocitySensorView.isAccessibilityElement = true
        
        updateHeadingSensor(value: 0.0)
        updateVelocitySensor(value: 0.0)
    }
    
    public override func didReceiveSensorData(_ data: SensorData) {
        super.didReceiveSensorData(data)
        
        if let velocityX = data.locator?.velocity?.x, let velocityY = data.locator?.velocity?.y {
            updateVelocitySensor(value: hypot(velocityX, velocityY))
        }
    }
    
    public override func didReceiveRollMessage(heading: Double, speed: Double) {
        super.didReceiveRollMessage(heading: heading, speed: speed)
        
        updateHeadingSensor(value: heading)
    }
    
    private func updateHeadingSensor(value: Double) {
        headingSensorView.accessibilityLabel = String(format: NSLocalizedString("heading.headingSensor.accessibilityLabel", value: "Heading. %0.f degrees", comment: "accessibility for heading sensor view. %.0f is the direction the robot is heading in degrees. ie 130 degrees"), value)
        headingSensorView.sensorValueLabel.text = String(format: NSLocalizedString("heading.headingSensor.sensorValue.text", value: "%.0f°", comment: "value of heading sensor readout, %.0f is the robots heading in degrees, ° is the symbol for degrees."), value)
    }
    
    private func updateVelocitySensor(value: Double) {
        velocitySensorView.accessibilityLabel = String(format: NSLocalizedString("heading.velocitySensor.accessibilityLabel", value: "Velocity. %.1f centimeters per second", comment: "accessibility for velocity sensor view. %.1f is the robots speed in centimeters per second, ie 13 cm/s"), value)
        velocitySensorView.sensorValueLabel.text = String(format: NSLocalizedString("heading.velocitySesnor.sensorValue.text", value: "%.1f cm/s", comment: "value of the velocity sensor readout, %.1f is the robots speed in centimeters per second, ie 13 cm/s"), value)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let pillWidth: CGFloat
        if isVeryCompact() {
            sensorStackView.axis = .vertical
            pillWidth = 75.0
        } else {
            pillWidth = 150.0
            sensorStackView.axis = isVerticallyCompact() ? .horizontal : .vertical
        }
        
        view.setNeedsUpdateConstraints()
        
        if headingSensorView.minimumPillWidth != pillWidth {
            view.setNeedsLayout()
        }
        
        headingSensorView.minimumPillWidth = pillWidth
        velocitySensorView.minimumPillWidth = pillWidth
    }
    
    public override func updateViewConstraints() {
        if isVeryCompact() {
            bottomSensorViewConstraint?.constant = 0.0
        } else {
            bottomSensorViewConstraint?.constant = -30.0
        }
        
        super.updateViewConstraints()
    }
    
    public override var liveViewSafeAreaFrame: CGRect {
        get {
            var safeFrame = super.liveViewSafeAreaFrame
            
            if sensorStackView.frame.minY < safeFrame.maxY {
                safeFrame.size.height = sensorStackView.frame.minY - safeFrame.minY
            }
            
            return safeFrame
        }
    }
    
    override var accessibilityBottomAnchor: NSLayoutYAxisAnchor {
        get {
            return sensorStackView.topAnchor
        }
    }
}
