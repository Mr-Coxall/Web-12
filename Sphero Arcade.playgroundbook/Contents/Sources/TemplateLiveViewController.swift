//
//  TemplateLiveViewController.swift
//  spheroArcade
//
//  Created by Jordan Hesse on 2017-04-26.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit

@objc(TemplateLiveViewController)
public class TemplateLiveViewController: LiveViewController {
    
    @IBOutlet weak var velocitySensorView: SensorDisplayView!
    @IBOutlet weak var headingSensorView: SensorDisplayView!
    @IBOutlet weak var accelSensorView: SensorDisplayView!
    @IBOutlet weak var gyroSensorView: SensorDisplayView!
    
    private var bottomSensorViewConstraint: NSLayoutConstraint?

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let bottomSensorConstraint = gyroSensorView.bottomAnchor.constraint(equalTo: liveViewSafeAreaGuide.bottomAnchor, constant: -30.0)
        NSLayoutConstraint.activate([
            bottomSensorConstraint
            ])
        bottomSensorViewConstraint = bottomSensorConstraint

        
        let velocityTitle = NSLocalizedString("template.velocitySensor.titleLabel", value: "Velocity", comment: "velocity sensor title, velocity is how fast Sphero is rolling")
        velocitySensorView.titleLabel.text = velocityTitle.uppercased()
        velocitySensorView.isAccessibilityElement = true

        let headingTitle = NSLocalizedString("template.headingSensor.titleLabel", value: "Heading", comment: "heading sensor title, heading is the direction Sphero is rolling")
        headingSensorView.titleLabel.text = headingTitle.uppercased()
        headingSensorView.isAccessibilityElement = true

        let accelTitle = NSLocalizedString("template.accelSensor.titleLabel", value: "Accelerometer", comment: "accelerometer sensor title, accelerometer is how fast Sphero is accelerating")
        accelSensorView.titleLabel.text = accelTitle.uppercased()
        accelSensorView.isAccessibilityElement = true
        
        let gyroTitle = NSLocalizedString("template.gyroSensor.titleLabel", value: "Gyroscope", comment: "gyro sensor title, gyroscope is have fast Sphero is spinning")
        gyroSensorView.titleLabel.text = gyroTitle.uppercased()
        gyroSensorView.isAccessibilityElement = true
        
        updateVelocitySensor(value: 0.0)
        updateHeadingSensor(value: 0.0)
        updateAccelSensor(value: 0.0)
        updateGyroSensor(value: 0.0)
    }
    
    public override var toyBoxConnectorItems: [ToyBoxConnectorItem] {
        get {
            return [
                ToyBoxConnectorItem(prefix: SPRKToy.descriptor,
                                    defaultName: NSLocalizedString("toy.name.sprk", value: "SPRK+", comment: "SPRK+ robot"),
                                    icon: UIImage(named: "connection-sphero")!),
                ToyBoxConnectorItem(prefix: BB8Toy.descriptor,
                                    defaultName: NSLocalizedString("toy.name.bb8", value: "BB-8", comment: "BB-8 robot"),
                                    icon: UIImage(named: "connection-bb8")!),
            ]
        }
    }
    
    public override func didReceiveSensorData(_ data: SensorData) {
        super.didReceiveSensorData(data)
        
        if let velocityX = data.locator?.velocity?.x, let velocityY = data.locator?.velocity?.y {
            updateVelocitySensor(value: hypot(velocityX, velocityY))
        }
        if let accelX = data.accelerometer?.filteredAcceleration?.x, let accelY = data.accelerometer?.filteredAcceleration?.y, let accelZ = data.accelerometer?.filteredAcceleration?.z {
            updateAccelSensor(value: sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ))
        }
        if let gyroX = data.gyro?.rotationRate?.x, let gyroY = data.gyro?.rotationRate?.y, let gyroZ = data.gyro?.rotationRate?.z {
            updateGyroSensor(value: sqrt(Double(gyroX * gyroX + gyroY * gyroY + gyroZ * gyroZ)) / 10.0)
        }
    }
    
    public override func didReceiveRollMessage(heading: Double, speed: Double) {
        super.didReceiveRollMessage(heading: heading, speed: speed)
        
        updateHeadingSensor(value: heading)
    }
    
    private func updateHeadingSensor(value: Double) {
        headingSensorView.accessibilityLabel = String(format: NSLocalizedString("template.headingSensor.accessibilityLabel", value: "Heading. %0.f degrees", comment: "accessibility for heading sensor view. %.0f is the direction the robot is heading in degrees. ie 130 degrees"), value)
        headingSensorView.sensorValueLabel.text = String(format: NSLocalizedString("template.headingSensor.sensorValue.text", value: "%.0f°", comment: "value of heading sensor readout, %.0f is the robots heading in degrees, ° is the symbol for degrees."), value)
    }
    
    private func updateVelocitySensor(value: Double) {
        velocitySensorView.accessibilityLabel = String(format: NSLocalizedString("template.velocitySensor.accessibilityLabel", value: "Velocity. %.1f centimeters per second", comment: "accessibility for velocity sensor view. %.1f is the robots speed in centimeters per second, ie 13 cm/s"), value)
        velocitySensorView.sensorValueLabel.text = String(format: NSLocalizedString("template.velocitySesnor.sensorValue.text", value: "%.1f cm/s", comment: "value of the velocity sensor readout, %.1f is the robots speed in centimeters per second, ie 13 cm/s"), value)
    }
    
    private func updateAccelSensor(value: Double) {
        accelSensorView.accessibilityLabel = String(format: NSLocalizedString("template.accelSensor.accessibilityLabel", value: "Accelerometer. %.1f g-forces", comment: "accessibility for accelerometer sensor view. %.0f is the acceleration the robot in g's. ie 1.4 g's"), value)
        accelSensorView.sensorValueLabel.text = String(format: NSLocalizedString("template.accelSensor.sensorValue.text", value: "%.1f g", comment: "value of accelerometer sensor readout, %.1f is the robots acceleration in g's. ie 1.4 g's"), value)
    }
    
    private func updateGyroSensor(value: Double) {
        gyroSensorView.accessibilityLabel = String(format: NSLocalizedString("template.gyroSensor.accessibilityLabel", value: "Gyroscope. %0.f degrees per second", comment: "accessibility for gyro sensor view. %.0f is the robots rate of rotation in degrees per second, ie 500 °/s"), value)
        gyroSensorView.sensorValueLabel.text = String(format: NSLocalizedString("template.gyroSensor.sensorValue.text", value: "%.0f °/s", comment: "value of the gyro sensor readout, %.0f is the robots rate of rotation in degrees per second, ie 500 °/s"), value)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let pillWidth: CGFloat = isVeryCompact() ? 75.0 : 150.0
       
        velocitySensorView.minimumPillWidth = pillWidth
        headingSensorView.minimumPillWidth = pillWidth
        accelSensorView.minimumPillWidth = pillWidth
        gyroSensorView.minimumPillWidth = pillWidth

        if velocitySensorView.minimumPillWidth != pillWidth {
            view.setNeedsLayout()
        }
    }
    
    public override func updateViewConstraints() {
        if isVeryCompact() {
            bottomSensorViewConstraint?.constant = 0.0
        } else {
            bottomSensorViewConstraint?.constant = -30.0
        }
        
        super.updateViewConstraints()
    }
    
}
