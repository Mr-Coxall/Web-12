//
//  VolleyLiveViewController.swift
//  spheroArcade
//
//  Created by Jeff Payan on 2017-03-31.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

@objc(BounceAngleLiveViewController)
public class BounceAngleLiveViewController: ToyDisplayViewController {
    
    @IBOutlet weak var sensorDataStackView: UIStackView!
    @IBOutlet weak var headingSensorView: SensorDisplayView!
    @IBOutlet weak var maxAngleSensorView: SensorDisplayView!
    @IBOutlet weak var minAngleSensorView: SensorDisplayView!
    @IBOutlet weak var firstTextLabel: UILabel!
    @IBOutlet weak var secondTextLabel: UILabel!
    @IBOutlet weak var straightLineLabel: UILabel!
    @IBOutlet weak var thirdTextLabel: UILabel!
    @IBOutlet weak var bounceAngleImage: UIImageView!
    @IBOutlet weak var minInputLabel: UILabel!
    @IBOutlet weak var maxInputLabel: UILabel!
    @IBOutlet weak var bounceAngleAccessibilityContainer: UIView!
    @IBOutlet weak var bottomBounceAngleConstraint: NSLayoutConstraint!
    
    private var lowerBounds: Int?
    private var upperBounds: Int?
    private var randomNumberGenerated: Int?
    private var bottomSensorConstraint: NSLayoutConstraint?
    private var isRunning: Bool = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        toyScene.setOriginDotColor(UIColor(red: 112.0/255.0, green: 184.0/255.0, blue: 231.0/255.0, alpha: 1.0))
        
        headingSensorView.preferredSize = .compact
        maxAngleSensorView.preferredSize = .compact
        minAngleSensorView.preferredSize = .compact
        
        headingSensorView.orientation = .vertical
        maxAngleSensorView.orientation = .vertical
        minAngleSensorView.orientation = .vertical
        
        
        bounceAngleAccessibilityContainer.accessibilityLabel = NSLocalizedString("bounceAngle.diagram.accessibility", value: "Diagram of Sphero bouncing off a wall. A single vertical line coming from Sphero, indicating a base angle of 180 degrees. Two angled lines coming from Sphero forming a cone, indicating the range of possible directions it will travel after the collision. The left bound of the cone indicating the minimum value passed into the random function. The right bound of the cone indicating the maximum value passed into the random function.", comment: "bounce angle page image accessibility, image is a diagram showing various angles that Sphero will roll back at after a collision.")
        
        minInputLabel.text = NSLocalizedString("bounceAngle.minInput.text", value: "min input", comment: "bounce angle diagram, 'min input' is the minimum value the user would input for a random number generator")
        maxInputLabel.text = NSLocalizedString("bounceAngle.maxInput.text", value: "max input", comment: "bounce angle diagram, 'max input' is the maximum value the user would input for a random number generator")
        
        headingSensorView.titleLabel.text = NSLocalizedString("bounceAngle.headingSensor.titleLabel", value: "Heading", comment: "title label for a sensor display, 'Heading' is direction, i.e/ Sphero's currenting heading is 180 degrees")
        headingSensorView.sensorValueLabel.text = NSLocalizedString("bounceAngle.headingSensor.value", value: "180°", comment: "180 degrees, indicating direction Sphero is rolling")
        firstTextLabel.text = NSLocalizedString("bounceAngle.sensorView.randomSplice", value: "+ random (", comment: "first part of a string splice. complete string is '180 + random (input to input), where the numbers are degrees and random (0 to 0) is a random number between 'input' and 'input' where inputs are user supplied numbers")
        
        minAngleSensorView.titleLabel.text = NSLocalizedString("bounceAngle.sensorView.minInput.titleLabel", value: "Min", comment: "title label for minimum value user provides to random number function")
        maxAngleSensorView.titleLabel.text = NSLocalizedString("bounceAngle.sensorView.maxInput.titleLabel", value: "Max", comment: "title label for maximum value user provides to random number function")
        
        secondTextLabel.text = NSLocalizedString("bounceAngle.sensorView.secondTextLabel", value: "to", comment: "middle part of a string splice, complete string is '180 + random (input to input), where the numbers are degrees and random (0 to 0) is a random number between 'input' and 'input' where inputs are user supplied numbers")
        
        thirdTextLabel.text = NSLocalizedString("bounceAngle.sensorView.thirdTextLabel", value: ")", comment: "last part of a string splice, complete string is '180 + random (input to input), where the numbers are degrees and random (input to input) is a random number between 'input' and 'input' where inputs are user supplied numbers")
        let inputText = NSLocalizedString("bounceAngle.sensorView.inputText", value: "input", comment: "random number input value placeholder")
        maxAngleSensorView.sensorValueLabel.text = inputText
        minAngleSensorView.sensorValueLabel.text = inputText
        
        sensorDataStackView.isAccessibilityElement = true
        sensorDataStackView.accessibilityLabel = NSLocalizedString("bounceAngle.sensorViews.accessibilityLabel", value: "The outgoing heading will be the 180 degrees plus a random number between min and max.", comment: "bounce angle sensor accessibility, initial state.")
        
        let sensorConstraint = sensorDataStackView.bottomAnchor.constraint(equalTo: liveViewSafeAreaGuide.bottomAnchor, constant: -60.0)
        NSLayoutConstraint.activate([
            sensorConstraint
            ])
        
        bottomSensorConstraint = sensorConstraint
    }
    
    
    public override func didReceiveCollision(data: CollisionData) {
        super.didReceiveCollision(data: data)
        
        toyScene.showCollision(data: data)
        updateSensorDisplays()
    }
    
    public override func liveViewMessageConnectionOpened() {
        super.liveViewMessageConnectionOpened()
        
        isRunning = true
        updateSensorDisplays()
    }
    
    private func updateSensorDisplays() {
        firstTextLabel.text = "+"
        secondTextLabel.text = "="
        thirdTextLabel.text = ""
        
        minAngleSensorView.titleText = NSLocalizedString("bounceAngle.sensorView.randomNumberTitle", value: "Randomized Number", comment: "title label, title for the random number that was generated from the random function.")
        maxAngleSensorView.titleText = NSLocalizedString("bounceAngle.sensorView.outgoingTitle", value: "Outgoing Heading", comment: "title label, title for the total outgoing heading, where heading is direction. i.e/ 180 degrees + 32 (random number) = 112 degrees outgoing heading")
        
        minAngleSensorView.titleLabel.textAlignment = .center
        maxAngleSensorView.titleLabel.textAlignment = .center
        
        let minDisplayValue: String
        let maxDisplayValue: String
        
        if let randomNumber = randomNumberGenerated {
            minDisplayValue = String(format: "%d", randomNumber)
            maxDisplayValue = String(format: "%d°", 180 + randomNumber)
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, sensorDataStackView)
            sensorDataStackView.accessibilityLabel = String(format: NSLocalizedString("bounceAngle.sensorViews.accessibilityLabelFinal", value: "The outgoing heading was 180 degrees plus the randomly generated %d degrees, totalling %d degrees.", comment: "bounce angle sensor view accessibility, first %d is a randomly generated number, second %d is the final bounce angle. string reads ...plus the randomly generated 32 degrees, totalling 212 degrees."), randomNumber, 180 + randomNumber)
        } else {
            sensorDataStackView.accessibilityLabel = NSLocalizedString("bounceAngle.sensorViews.accessibilityLabelIncomplete", value: "The outgoing heading will be 180 degrees plus a random number which has not yet been calculated.", comment: "bounce angle sensor accessibility, interim state before Sphero has collided.")
            minDisplayValue = "?"
            maxDisplayValue = "?"
        }
        
        minAngleSensorView.sensorValueLabel.text = minDisplayValue
        maxAngleSensorView.sensorValueLabel.text = maxDisplayValue
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isRunning {
            updateSensorDisplays()
        }
    }
    
    public override func updateViewConstraints() {
        if isVeryCompact() {
            bottomSensorConstraint?.constant = 0.0
        } else {
            bottomSensorConstraint?.constant = isVerticallyCompact() ? -10.0 : -60.0
            bottomBounceAngleConstraint.constant = isVerticallyCompact() ? 150.0 : 200.0
        }
        
        super.updateViewConstraints()
    }
    
    public override func onReceive(message: PlaygroundValue) {
        guard let dict = message.dictValue(),
            let typeId = dict[MessageKeys.type]?.intValue()
            else { return }
        
        if typeId == MessageTypeId.randomNumberGenerated.rawValue {
            if let minimum = dict[MessageKeys.randomNumberMinimum]?.intValue() {
                lowerBounds = minimum
            }
            
            if let maximum = dict[MessageKeys.randomNumberMaximum]?.intValue() {
                upperBounds = maximum
            }
            
            if let generated = dict[MessageKeys.randomNumberGenerated]?.intValue() {
                randomNumberGenerated = generated
            }
            
            updateSensorDisplays()
        }
    }
    
    public override var liveViewSafeAreaFrame: CGRect {
        get {
            var safeFrame = super.liveViewSafeAreaFrame
            
            if sensorDataStackView.frame.minY < safeFrame.maxY {
                safeFrame.size.height = sensorDataStackView.frame.minY - safeFrame.minY
            }
            
            return safeFrame
        }
    }
}
