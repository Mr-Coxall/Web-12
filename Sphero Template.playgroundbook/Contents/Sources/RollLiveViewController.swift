//
//  RollLiveViewController.swift
//  spheroArcade
//
//  Created by Jordan Hesse on 2017-03-21.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit

@objc(RollLiveViewController)
public class RollLiveViewController: LiveViewController {
    
    @IBOutlet weak var toyImageView: UIImageView!
    @IBOutlet weak var linesImageView1: UIImageView!
    @IBOutlet weak var linesImageView2: UIImageView!
    @IBOutlet weak var linesImageView3: UIImageView!
    @IBOutlet weak var linesImageView4: UIImageView!
    
    @IBOutlet weak var sensorDisplayView: SensorDisplayView!
    @IBOutlet weak var rollAccessibilityContainer: UIView!
    
    public override var shouldPresentAim: Bool {
        return false
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        NSLayoutConstraint.activate([
            sensorDisplayView.bottomAnchor.constraint(equalTo: liveViewSafeAreaGuide.bottomAnchor, constant: -20.0)
            ])
        
        let velocityText = NSLocalizedString("roll.sensorView.title", value: "Velocity", comment: "sensor view title label, title for how fast Sphero is travelling")
        sensorDisplayView.titleLabel.text = velocityText.uppercased()
        
        sensorDisplayView.orientation = .horizontal
        sensorDisplayView.preferredSize = .expanded
        sensorDisplayView.isAccessibilityElement = true
        
        linesImageView1.alpha = 0.0
        linesImageView2.alpha = 0.0
        linesImageView3.alpha = 0.0
        linesImageView4.alpha = 0.0
        
        updateSensorLabels(from: nil)
    }
    
    public override func didReceiveRollMessage(heading: Double, speed: Double) {
        let speed = max(0.0, min(speed, 255.0))
        animateRoll(withSpeed: speed)
    }
    
    public override func didReceiveSensorData(_ data: SensorData) {
        updateSensorLabels(from: data)
    }

    private func animateRoll(withSpeed speed: Double) {
        let key = "roll"
        let keyPath = "transform.rotation.z"
        
        let transformZ = toyImageView.layer.presentation()?.value(forKeyPath: keyPath) as? CGFloat
            ?? toyImageView.layer.value(forKeyPath: keyPath) as? CGFloat ?? 0.0
        toyImageView.layer.removeAnimation(forKey: key)
        
        if speed > .ulpOfOne {
            let animation = CABasicAnimation(keyPath: keyPath)
            animation.toValue = transformZ + (.pi * 2.0)
            animation.fromValue = transformZ
            animation.duration = 0.5 + (1.0 * (255.0 - speed) / 255.0)
            animation.repeatCount = Float.greatestFiniteMagnitude
            toyImageView.layer.add(animation, forKey: key)
        } else {
            toyImageView.layer.transform = CATransform3DMakeRotation(transformZ, 0.0, 0.0, 1.0)
        }
        
        updateLines(withSpeed: speed)
    }
    
    private func updateLines(withSpeed speed: Double) {
        if speed > .ulpOfOne {
            let duration = 0.3
            let delay = 0.1 + (0.2 * (255.0 - speed) / 255.0)
            animateLines(linesImageView1, alpha: 1.0, duration: duration, delay: delay * 0.0)
            animateLines(linesImageView2, alpha: 0.8, duration: duration, delay: delay * 1.0)
            animateLines(linesImageView3, alpha: 0.6, duration: duration, delay: delay * 2.0)
            animateLines(linesImageView4, alpha: 0.4, duration: duration, delay: delay * 3.0)
        } else {
            let duration = 0.1
            animateLines(linesImageView1, alpha: 0.0, duration: duration, delay: duration * 3.0)
            animateLines(linesImageView2, alpha: 0.0, duration: duration, delay: duration * 2.0)
            animateLines(linesImageView3, alpha: 0.0, duration: duration, delay: duration * 1.0)
            animateLines(linesImageView4, alpha: 0.0, duration: duration, delay: duration * 0.0)
        }
    }
    
    private func animateLines(_ lines: UIView, alpha: CGFloat, duration: TimeInterval, delay: TimeInterval) {
        UIView.animate(withDuration: duration, delay: delay,
                       options: [.beginFromCurrentState, .curveEaseInOut], animations: {
                        lines.alpha = alpha
        }, completion: nil)
    }

    private func updateAccessibilityLabels(withSpeed speed: Double) {
        sensorDisplayView.accessibilityLabel = String(format: NSLocalizedString("roll.sensorView.accesibilityText.", value: "Velocity. %.0f centimeters per second", comment: "roll velocity sensor accesibility, %.0f is how fast the robot is travelling in centimeters per second, i.e. 13 cm/s"), speed)
        
        if speed > .ulpOfOne {
            rollAccessibilityContainer.accessibilityLabel = NSLocalizedString("roll.accessibilityContainer.MovingAccessibility", value: "Sphero is rolling to the right with trailing circles indicating movement.", comment: "roll page image accessbility, image is of rolling to the right")
        } else {
            rollAccessibilityContainer.accessibilityLabel = NSLocalizedString("roll.accessibilityContainer.NoSpeedAccessibility", value: "Sphero is stationary.", comment: "roll page image accessbility, image is of Sphero sitting in the middle of the screen")
        }
    }
    
    private func updateSensorLabels(from data: SensorData?) {
        let velocity = hypot(data?.locator?.velocity?.x ?? 0.0, data?.locator?.velocity?.y ?? 0.0)
        updateAccessibilityLabels(withSpeed: velocity)
        sensorDisplayView.sensorValueLabel.text = String(format: NSLocalizedString("roll.sensorView.sensorValue", value: "%.0f cm/s", comment: "roll velocity sensor display, %.0f is how fast the robot is travelling in centimeters per second, i.e. 13 cm/s"), velocity)
    }
    
}
