//
//  ToyMessage.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-16.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

extension PlaygroundValue {
    
    public func doubleValue() -> Double? {
        
        switch self {
        case .floatingPoint(let value):
            return value
        default:
            return nil
        }
    }
    
    public func stringValue() -> String? {
        switch self {
        case .string(let value):
            return value
        default:
            return nil
        }
    }
    
    public func dictValue() -> [String:PlaygroundValue]? {
        switch self {
        case .dictionary(let dict):
            return dict
        default:
            return nil
        }
    }
    
    public func intValue() -> Int? {
        switch self {
        case .integer(let value):
            return value
        default:
            return nil
        }
    }
    
    public func boolValue() -> Bool? {
        switch self {
        case .boolean(let value):
            return value
        default:
            return nil
        }
    }
    
    public func colorValue() -> UIColor? {
        guard let dict = self.dictValue(),
            let red = dict[MessageKeys.red]?.doubleValue(),
            let green = dict[MessageKeys.green]?.doubleValue(),
            let blue = dict[MessageKeys.blue]?.doubleValue(),
            let alpha = dict[MessageKeys.alpha]?.doubleValue() else { return nil }
        
        return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
    
    public init(color: UIColor) {
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        self = .dictionary([
            MessageKeys.red: PlaygroundValue.floatingPoint(Double(red)),
            MessageKeys.green: PlaygroundValue.floatingPoint(Double(green)),
            MessageKeys.blue: PlaygroundValue.floatingPoint(Double(blue)),
            MessageKeys.alpha: PlaygroundValue.floatingPoint(Double(alpha)),
        ])
    }
}

public enum MessageTypeId: Int {
    case connect = 0
    case didConnect = 1
    
    case roll = 2
    case stopRoll = 3
    
    case setMainLed = 4
    case setBackLed = 5
    
    case setStabilization = 6
    
    case setCollisionDetection = 9
    case collisionDetected = 10
    
    case startAiming = 15
    case stopAiming = 16
    
    case sensorData = 17
    case enableSensors = 18
    case configureLocator = 19
    
    case toyReady = 20

    case randomNumberGenerated = 21
    
    case startPong = 30
    case pongEnded = 31
    case pongCurrentPlayerChanged = 32
    case showTimer = 33
    
    case pointsScored = 40
    
    case playAssessmentSound = 41
    
    public func playgroundValue() -> PlaygroundValue {
        return PlaygroundValue.integer(self.rawValue)
    }
    
    public init?(value: PlaygroundValue) {
        guard let rawValue = value.intValue() else { return nil }
        guard let typeId = MessageTypeId(rawValue: rawValue) else { return nil }
        
        self = typeId
    }
}

public enum MessageKeys {
    public static let type = "type"
    
    public static let speed = "speed"
    public static let heading = "heading"
    
    public static let mainLedColor = "mainLedColor"
    
    public static let red = "red"
    public static let green = "green"
    public static let blue = "blue"
    public static let alpha = "alpha"
    
    public static let brightness = "brightness"
    
    public static let state = "state"
    
    public static let impactAcceleration = "impactAcceleration"
    public static let impactAxis = "impactAxis"
    public static let impactPower = "impactPower"
    public static let impactSpeed = "impactSpeed"
    public static let timestamp = "timestamp"
    
    public static let detectionMethod = "detectionMethod"
    public static let threshold = "threshold"
    public static let speedThreshold = "speedThreshold"
    public static let postTimeDeadZone = "postTimeDeadZone"

    public static let newX = "newX"
    public static let newY = "newY"
    public static let newYaw = "newYaw"
    
    public static let sensorMask = "sensorMask"
    public static let locator = "locator"
    public static let orientation = "orientation"
    public static let gyro = "gyro"
    public static let accelerometer = "accelerometer"
    public static let position = "position"
    public static let velocity = "velocity"
    public static let filtered = "filtered"
    public static let raw = "raw"
    
    public static let x = "x"
    public static let y = "y"
    public static let z = "z"
    
    public static let initialBallSpeed = "initialBallSpeed"
    public static let maximumBallSpeed = "maximumBallSpeed"
    public static let ballSpeedIncrement = "ballSpeedIncrement"
    
    public static let pongLeftPaddleColor = "pongLeftPaddleColor"
    public static let pongRightPaddleColor = "pongRightPaddleColor"
    public static let pongBallColor = "pongBallColor"
    public static let pongBackgroundColor = "pongBackgroundColor"
    
    public static let playerNumber = "playerNumber"
    public static let points = "points"
    
    public static let time = "time"
    
    public static let randomNumberMinimum = "randomNumberMinimum"
    public static let randomNumberMaximum = "randomNumberMaximum"
    public static let randomNumberGenerated = "randomNumberGenerated"
    
    public static let assessmentSoundKey = "assessmentSoundKey"
}

public class ToyMessageSender: ToyCommandListener {
    
    public init() {}
    
    private func send(_ value: PlaygroundValue) {
        PlaygroundHelpers.sendMessageToLiveView(value)
    }
    
    public func roll(heading: Double, speed: Double) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.roll.playgroundValue(),
            MessageKeys.heading: PlaygroundValue.floatingPoint(heading),
            MessageKeys.speed: PlaygroundValue.floatingPoint(speed)
            ]))
    }

    public func stopRoll(heading: Double) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.stopRoll.playgroundValue(),
            MessageKeys.heading: PlaygroundValue.floatingPoint(heading)
            ]))
    }
    
    public func setMainLed(color: UIColor) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.setMainLed.playgroundValue(),
            MessageKeys.mainLedColor: PlaygroundValue(color: color)
        ]))
    }
    
    public func setBackLed(brightness: Double) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.setBackLed.playgroundValue(),
            MessageKeys.brightness: PlaygroundValue.floatingPoint(brightness)
            ]))
    }
    
    public func setStabilization(state: SetStabilization.State) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.setStabilization.playgroundValue(),
            MessageKeys.state: PlaygroundValue.integer(Int(state.rawValue))
            ]))
    }
    
    public func setCollisionDetection(configuration: ConfigureCollisionDetection.Configuration) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.setCollisionDetection.playgroundValue(),
            MessageKeys.detectionMethod: PlaygroundValue.integer(Int(configuration.detectionMethod.rawValue)),
            MessageKeys.threshold: PlaygroundValue.dictionary([
                MessageKeys.x: PlaygroundValue.integer(Int(configuration.xThreshold)),
                MessageKeys.y: PlaygroundValue.integer(Int(configuration.yThreshold))]),
            MessageKeys.speedThreshold: PlaygroundValue.dictionary([
                MessageKeys.x: PlaygroundValue.integer(Int(configuration.xSpeedThreshold)),
                MessageKeys.y: PlaygroundValue.integer(Int(configuration.ySpeedThreshold))]),
            MessageKeys.postTimeDeadZone: PlaygroundValue.floatingPoint(configuration.postTimeDeadZone)
            ]))
    }
    
    public func enableSensors(sensorMask: SensorMask) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.enableSensors.playgroundValue(),
            MessageKeys.sensorMask: PlaygroundValue.integer(Int(sensorMask.rawValue))
            ]))
    }
    
    public func startAiming() {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.startAiming.playgroundValue()
            ]))
    }
    
    public func stopAiming() {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.stopAiming.playgroundValue()
            ]))
    }
    
    public func configureLocator(newX: Double, newY: Double, newYaw: Double) {
        send(.dictionary([
            MessageKeys.type: MessageTypeId.configureLocator.playgroundValue(),
            MessageKeys.newX: PlaygroundValue.floatingPoint(Double(newX)),
            MessageKeys.newY: PlaygroundValue.floatingPoint(Double(newY)),
            MessageKeys.newYaw: PlaygroundValue.floatingPoint(Double(newYaw)),
            ]))
    }
    
}

