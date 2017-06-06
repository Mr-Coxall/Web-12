//
//  LiveViewController+Messages.swift
//  spheroArcade
//
//  Created by Jordan Hesse on 2017-03-28.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

extension LiveViewController: PlaygroundLiveViewMessageHandler {
    typealias MessageDict = Dictionary<String, PlaygroundSupport.PlaygroundValue>
    
    public func liveViewMessageConnectionOpened() {
        // This is run when the user presses "Run Code" in the playgrounds app.
        isLiveViewMessageConnectionOpened = true
        
        // Show aiming controller
        if shouldPresentAim && connectedToy != nil {
            showAimingController()
        }
        
        if shouldAutomaticallyConnectToToy && connectedToy == nil {
            connectionHintArrowView.show()
        }
        
        // Fade out our overlay if we have one
        if overlayView != nil {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.5) {
                    self.overlayView?.alpha = 0.0
                }
            }
        }
    }
    
    public func liveViewMessageConnectionClosed() {
        // This is run when the user presses the stop button.
        isLiveViewMessageConnectionOpened = false
        
        // Make sure Sphero doesn't roll indefinitely and turn off the back LED
        connectedToy?.stopRoll(heading: 0.0)
        connectedToy?.sensorControl.disable()
        connectedToy?.setCollisionDetection(configuration: .disabled)
        connectedToy?.setBackLed(brightness: 0.0)
        connectedToy?.setStabilization(state: .on)
        
        didReceiveRollMessage(heading: 0.0, speed: 0.0)
        didReceiveSetBackLedMesssage(brightness: 0.0)
        
        // Dismiss aiming view
        if let aimingViewController = aimingViewController {
            removeModalViewController(aimingViewController) { (_) in
                self.aimingViewController = nil
            }
        }
        connectionHintArrowView.hide()
    }
    
    public func receive(_ message: PlaygroundValue) {
        guard let dict = message.dictValue(),
            let typeIdValue = dict[MessageKeys.type],
            let typeId = MessageTypeId(value: typeIdValue) else { return }
            
        switch typeId {
        case .roll:
            sendRoll(dict:  dict)
            
        case .startAiming:
            connectedToy?.startAiming()
            
        case .stopAiming:
            connectedToy?.stopAiming()
            
        case .setMainLed:
            sendSetMainLed(dict: dict)
            
        case .stopRoll:
            sendStopRoll(dict: dict)
            
        case .configureLocator:
            sendConfigureLocator(dict: dict)
        
        case .enableSensors:
            sendEnableSensors(dict: dict)
            
        case .connect:
            if connectedToy == nil {
                if !shouldAutomaticallyConnectToToy {
                    connectToNearest()
                }
            } else if shouldPresentAim {
                showAimingController()
            } else {
                sendToyReadyMessage()
            }
            
        case .setBackLed:
            sendSetBackLed(dict: dict)
            
        case .setStabilization:
            sendSetStabilization(dict: dict)
            
        case .setCollisionDetection:
            sendSetCollisionDetection(dict: dict)
        
        case .playAssessmentSound:
            playSound(dict: dict)
            
        default:
            break
        }
        
        // This method can't be overridden (yet) because it's defined in an extension.
        // Instead, allow subclasses to override onReceive and pass messages to that too.
        onReceive(message: message)
    }
    
    func playSound(dict: MessageDict) {
        guard let passSound = dict[MessageKeys.assessmentSoundKey]?.intValue() else { return }
        playAssessmentSound(playPassSound: (passSound == 0 ? false : true))
    }
    
    func sendCollisionMessage(data: CollisionData) {
        let message = PlaygroundValue.dictionary([
            MessageKeys.type: MessageTypeId.collisionDetected.playgroundValue(),
            MessageKeys.impactAcceleration: .dictionary([
                MessageKeys.x: .floatingPoint(data.impactAcceleration.x),
                MessageKeys.y: .floatingPoint(data.impactAcceleration.y),
                MessageKeys.z: .floatingPoint(data.impactAcceleration.z),
                ]),
            MessageKeys.impactPower: .dictionary([
                MessageKeys.x: .floatingPoint(data.impactPower.x),
                MessageKeys.y: .floatingPoint(data.impactPower.y),
                ]),
            MessageKeys.impactAxis: .dictionary([
                MessageKeys.x: .boolean(data.impactAxis.x),
                MessageKeys.y: .boolean(data.impactAxis.y),
                ]),
            MessageKeys.impactSpeed: .floatingPoint(data.impactSpeed),
            MessageKeys.timestamp: .floatingPoint(data.timestamp)
            ])
        
        sendMessageToContents(message)
    }
    
    func sendSensorDataMessage(data: SensorData) {
        var dict: MessageDict = [
            MessageKeys.type: MessageTypeId.sensorData.playgroundValue()
        ]
        
        if let locator = data.locator {
            var sensorDict: MessageDict = [:]
            if let position = locator.position {
                var positionDict: MessageDict = [:]
                if let x = position.x {
                    positionDict[MessageKeys.x] = .floatingPoint(x)
                }
                if let y = position.y {
                    positionDict[MessageKeys.y] = .floatingPoint(y)
                }
                sensorDict[MessageKeys.position] = .dictionary(positionDict)
            }
            if let velocity = data.locator?.velocity {
                var velocityDict: MessageDict = [:]
                if let x = velocity.x {
                    velocityDict[MessageKeys.x] = .floatingPoint(x)
                }
                if let y = velocity.y {
                    velocityDict[MessageKeys.y] = .floatingPoint(y)
                }
                sensorDict[MessageKeys.velocity] = .dictionary(velocityDict)
            }
            dict[MessageKeys.locator] = .dictionary(sensorDict)
        }
        
        if let orientation = data.orientation {
            var sensorDict: MessageDict = [:]
            if let x = orientation.yaw {
                sensorDict[MessageKeys.x] = .integer(x)
            }
            if let y = orientation.pitch {
                sensorDict[MessageKeys.y] = .integer(y)
            }
            if let z = orientation.roll {
                sensorDict[MessageKeys.z] = .integer(z)
            }
            dict[MessageKeys.orientation] = .dictionary(sensorDict)
        }
        
        if let gyro = data.gyro {
            var sensorDict: MessageDict = [:]
            if let filtered = gyro.rotationRate {
                var filteredDict: MessageDict = [:]
                if let x = filtered.x {
                    filteredDict[MessageKeys.x] = .integer(x / 10)
                }
                if let y = filtered.y {
                    filteredDict[MessageKeys.y] = .integer(y / 10)
                }
                if let z = filtered.z {
                    filteredDict[MessageKeys.z] = .integer(z / 10)
                }
                sensorDict[MessageKeys.filtered] = .dictionary(filteredDict)
            }
            if let raw = gyro.rawRotation {
                var rawDict: MessageDict = [:]
                if let x = raw.x {
                    rawDict[MessageKeys.x] = .integer(x / 10)
                }
                if let y = raw.y {
                    rawDict[MessageKeys.y] = .integer(y / 10)
                }
                if let z = raw.z {
                    rawDict[MessageKeys.z] = .integer(z / 10)
                }
                sensorDict[MessageKeys.raw] = .dictionary(rawDict)
            }
            dict[MessageKeys.gyro] = .dictionary(sensorDict)
        }
        
        if let accelerometer = data.accelerometer {
            var sensorDict: MessageDict = [:]
            if let filtered = accelerometer.filteredAcceleration {
                var filteredDict: MessageDict = [:]
                if let x = filtered.x {
                    filteredDict[MessageKeys.x] = .floatingPoint(x)
                }
                if let y = filtered.y {
                    filteredDict[MessageKeys.y] = .floatingPoint(y)
                }
                if let z = filtered.z {
                    filteredDict[MessageKeys.z] = .floatingPoint(z)
                }
                sensorDict[MessageKeys.filtered] = .dictionary(filteredDict)
            }
            if let raw = accelerometer.rawAcceleration {
                var rawDict: MessageDict = [:]
                if let x = raw.x {
                    rawDict[MessageKeys.x] = .integer(x)
                }
                if let y = raw.y {
                    rawDict[MessageKeys.y] = .integer(y)
                }
                if let z = raw.z {
                    rawDict[MessageKeys.z] = .integer(z)
                }
                sensorDict[MessageKeys.raw] = .dictionary(rawDict)
            }
            dict[MessageKeys.accelerometer] = .dictionary(sensorDict)
        }
        
        let message = PlaygroundValue.dictionary(dict)
        sendMessageToContents(message)
    }
    
    func sendToyReadyMessage() {
        guard !requiresFirmwareUpdate(for: connectedToy) else { return }

        sendMessageToContents(
            .dictionary([
                MessageKeys.type: MessageTypeId.toyReady.playgroundValue()
                ])
        )
    }
    
    func sendRoll(dict: MessageDict) {
        guard let speed = dict[MessageKeys.speed]?.doubleValue(),
            let heading = dict[MessageKeys.heading]?.doubleValue() else { return }
        
        connectedToy?.roll(heading: heading, speed: speed)
        didReceiveRollMessage(heading: heading, speed: speed)
    }
    
    func sendStopRoll(dict: MessageDict) {
        guard let heading = dict[MessageKeys.heading]?.doubleValue() else { return }
        
        connectedToy?.stopRoll(heading: heading)
        didReceiveRollMessage(heading: heading, speed: 0.0)
    }
    
    func sendConfigureLocator(dict: MessageDict) {
        guard let newX = dict[MessageKeys.newX]?.doubleValue(),
            let newY = dict[MessageKeys.newY]?.doubleValue(),
            let newYaw = dict[MessageKeys.newYaw]?.doubleValue()
             else { return }
        connectedToy?.configureLocator(newX: newX, newY: newY, newYaw: newYaw)
    }
    
    func sendSetMainLed(dict: MessageDict) {
        guard let color = dict[MessageKeys.mainLedColor]?.colorValue() else { return }
        
        connectedToy?.setMainLed(color: color)
        didReceiveSetMainLedMessage(color: color)
    }
    
    func sendSetBackLed(dict: MessageDict) {
        guard let brightness = dict[MessageKeys.brightness]?.doubleValue() else { return }
        
        connectedToy?.setBackLed(brightness: brightness)
        didReceiveSetBackLedMesssage(brightness: brightness)
    }
    
    func sendSetStabilization(dict: MessageDict) {
        guard let rawState = dict[MessageKeys.state]?.intValue(),
            let state = SetStabilization.State(rawValue: UInt8(rawState)) else { return }
        
        connectedToy?.setStabilization(state: state)
        didReceiveSetStabilizationMesssage(state: state)
    }
    
    func sendEnableSensors(dict: MessageDict) {
        guard let rawMask = dict[MessageKeys.sensorMask]?.intValue() else { return }
        if UInt64(rawMask) != SensorMask.off.rawValue {
            let sensorMask = SensorMask(rawValue: UInt64(rawMask))
            connectedToy?.sensorControl.enable(sensors: sensorMask)
            didReceiveEnableSensorsMessage(sensors: sensorMask)
        } else {
            connectedToy?.sensorControl.disable()
            didReceiveEnableSensorsMessage(sensors: [])
        }
    }
    
    func sendSetCollisionDetection(dict: MessageDict) {
        guard let rawMethod = dict[MessageKeys.detectionMethod]?.intValue(),
            let detectionMethod = ConfigureCollisionDetection.DetectionMethod(rawValue: UInt8(rawMethod)),
            let threshold = dict[MessageKeys.threshold]?.dictValue(),
            let xThreshold = threshold[MessageKeys.x]?.intValue(),
            let yThreshold = threshold[MessageKeys.y]?.intValue(),
            let speedThreshold = dict[MessageKeys.speedThreshold]?.dictValue(),
            let xSpeedThreshold = speedThreshold[MessageKeys.x]?.intValue(),
            let ySpeedThreshold = speedThreshold[MessageKeys.y]?.intValue(),
            let postTimeDeadZone = dict[MessageKeys.postTimeDeadZone]?.doubleValue() else { return }
        
        let configuration = ConfigureCollisionDetection.Configuration(
            detectionMethod: detectionMethod,
            xThreshold: UInt8(xThreshold),
            xSpeedThreshold: UInt8(xSpeedThreshold),
            yThreshold: UInt8(yThreshold),
            ySpeedThreshold: UInt8(ySpeedThreshold),
            postTimeDeadZone: postTimeDeadZone
        )
        
        connectedToy?.setCollisionDetection(configuration: configuration)
        didReceiveSetCollisionDetectionMesssage(configuration: configuration)
    }
    
}
