//
//  ContentHelpers.swift
//  spheroArcade
//
//  Created by Jordan Hesse on 2017-03-28.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit

fileprivate let toyBox = ToyBoxWrapper()
fileprivate var connectedToy: ToyWrapper?
fileprivate var currentHeading: Int = 0

fileprivate let userCodeQueue = DispatchQueue(label: "com.sphero.code.queue", attributes: .concurrent)

public func setupContent(assessment: AssessmentController, userCode: @escaping (() -> ())) {
    toyBox.addConnectionCallback(callback: { (toy: ToyWrapper) in
        connectedToy = toy
        currentHeading = 0
        assessment.assess(toy: toy, userCode: userCode, queue: userCodeQueue)
    })
    toyBox.readyToy()
}

/// Changes the color of the main LED lights.
/// You can turn off the lights by passing in `.black`.
///
/// - Parameter color: The desired color.
public func setMainLed(color: UIColor) {
    connectedToy?.setMainLed(color: color)
}

/// Sets the brightness of the back aiming LED, which is blue color only.
///
/// - Parameter brightness: The brightness of the LED from 0 to 255.
public func setBackLed(brightness: Int) {
    connectedToy?.setBackLed(brightness: Double(brightness))
}

/// Turns the stabilization system on or off, which is used for aiming.
/// Stabilization is on by default to keep Sphero upright inside it's shell.
///
/// - Parameter state: The desired state.
public func setStabilization(state: SetStabilization.State) {
    connectedToy?.setStabilization(state: state)
}

/// Turns collision detection on or off.
/// Use the `.enabled` (on) and `.disabled` (off) configurations.
///
/// - Parameter configuration: The collison detection parameters.
public func setCollisionDetection(configuration: ConfigureCollisionDetection.Configuration) {
    connectedToy?.setCollisionDetection(configuration: configuration)
}

/// Rolls Sphero at a given heading and speed.
///
/// - Parameters:
///   - heading: The target heading from 0° to 360°.
///   - speed: The target speed from 0 to 255.
public func roll(heading: Int, speed: Int) {
    currentHeading = heading
    connectedToy?.roll(heading: Double(heading), speed: Double(speed))
}

/// Sets the target speed to 0, stopping Sphero.
public func stopRoll() {
    connectedToy?.stopRoll(heading: Double(currentHeading))
}

/// Enters *aiming* mode allowing you to set the forward heading. After Sphero has been aimed, call `stopAiming()`.
public func startAiming() {
    connectedToy?.startAiming()
}

/// Exits *aiming* mode and applies the new aim angle.
public func stopAiming() {
    connectedToy?.stopAiming()
}

/// Enables streaming sensors.
/// You can select which sensors (locator, accelerometer, gyroscope, orientation) to enable with a `sensorMask`. Use `addSensorListener` to listen for sensor data.
///
/// - Parameter sensorMask: A list of sensors to enable.
public func enableSensors(sensorMask: SensorMask) {
    connectedToy?.enableSensors(sensorMask: sensorMask)
}

/// Disables streaming sensors.
public func disableSensors() {
    connectedToy?.enableSensors(sensorMask: [])
}

/// Registers a function that is called when Sphero collides with something.
/// Details about the collision are provided in `collisionData`.
///
/// - Parameter listener: The function to call when a collision occures.
public func addCollisionListener(_ listener: @escaping CollisionListener) {
    connectedToy?.addCollisionListener { (collisionData: CollisionData) in
        userCodeQueue.async {
            listener(collisionData)
        }
    }
}

/// Registers a function that is called when Sphero reports sensor data.
/// Sensor values are provided in `sensorData`.
///
/// - Parameter listener: The function to call when sensor data is received.
public func addSensorListener(_ listener: @escaping SensorListener) {
    connectedToy?.addSensorListener { (sensorData: SensorData) in
        userCodeQueue.async {
            listener(sensorData)
        }
    }
}

/// Sets the current (x, y) coordinates of the locator.
/// Call `configureLocator(newX: 0, newY: 0)` to reset the locator's position.
///
/// - Parameters:
///   - newX: the new X coordinate.
///   - newY: the new Y coordinate.
public func configureLocator(newX: Int, newY: Int) {
    connectedToy?.configureLocator(newX: Double(newX), newY: Double(newY), newYaw: 0.0)
}

/// Waits for a number of seconds before running the next sequence of code.
///
/// - Parameter seconds: the number of seconds to wait
public func wait(for seconds: Double) {
    usleep(UInt32(seconds * 1e6))
}
