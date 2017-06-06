//
//  SpheroV1ToyToy.swift
//  SpheroSDK
//
//  Created by Jeff Payan on 2017-03-14.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import UIKit

public class SpheroV1Toy: Toy, SensorControlProvider {
    
    lazy var sensorControl: SensorControl = SensorControl(toyCore: self.core)
    
    var freeFallAccelerationSquaredThreshold: Double = 0.2
    var freeFallTimeThreshold: TimeInterval = 0.175
    var isInFreeFall = false
    var lastLandedTime: TimeInterval?
    
    override init(identifier: UUID, core: Toy.ToyCore, owner: ToyBox) {
        super.init(identifier: identifier, core: core, owner: owner)
        
        core.addAsyncListener(self)
    }
    
    fileprivate func sendRollCommand(heading: UInt16, speed: UInt8, rollType: Roll.RollType) {
        core.send(Roll(heading: heading, speed: speed, state: rollType))
    }
    
    public func setMainLed(color: UIColor) {
        core.send(SetMainLEDColor(color: color))
    }
    
    public func setBackLed(brightness: Double) {
        core.send(SetBackLEDBrightness(brightness: UInt8(brightness.clamp(lowerBound: 0.0, upperBound: 255.0))))
    }
    
    public func configureLocator(newX: Double, newY: Double, newYaw: Double) {
        let max = Double(UInt16.max)
        core.send(ConfigureLocatorCommand(newX: UInt16(newX.clamp(lowerBound: 0.0, upperBound: max)),
                                          newY: UInt16(newY.clamp(lowerBound: 0.0, upperBound: max)),
                                          newYaw: UInt16(newY.clamp(lowerBound: 0.0, upperBound: max))))
    }
    
    fileprivate func sendHeadingCommand(heading: Double) {
        let intAngle = UInt16(heading.positiveRemainder(dividingBy: 360.0))
        core.send(UpdateHeadingCommand(heading: intAngle))
    }
    
    public func setStabilization(state: SetStabilization.State) {
        core.send(SetStabilization(state: state))
    }
    
    public func setCollisionDetection(configuration: ConfigureCollisionDetection.Configuration) {
        core.send(ConfigureCollisionDetection(configuration: configuration))
    }
    
    public func setToyOptions(_ options: ToyOptionsMask) {
        core.send(SetOptionsFlagsCommand(options: options))
    }
    
    public var onCollisionDetected: ((_ collisionData: CollisionData) -> Void)?
    public var onFreeFallDetected: ((Void) -> Void)?
}

//MARK: AsyncMessageListener
extension SpheroV1Toy: ToyCoreAsyncListener {
    
    func toyCore(_ toyCore: Toy.ToyCore, didReceiveAsyncResponse response: AsyncCommandResponse) {
        switch response {
        case let collisionData as CollisionDataCommandResponse:
            onCollisionDetected?(collisionData)
            
        case let sensorData as SensorDataCommandResponse:
            guard let acceleration = sensorData.accelerometer?.filteredAcceleration,
                let accelX = acceleration.x,
                let accelY = acceleration.y,
                let accelZ = acceleration.z else { return }
            
            let accelerationVector = [
                accelX,
                accelY,
                accelZ
            ]
            
            let accelerationSquared = accelerationVector.map({$0 * $0}).reduce(0, +)
            let isFreeFall = accelerationSquared < freeFallAccelerationSquaredThreshold
            let now = Date().timeIntervalSince1970
            
            if isFreeFall {
                if let lastLandedTime = lastLandedTime {
                    if !isInFreeFall && now - lastLandedTime > freeFallTimeThreshold {
                        isInFreeFall = true
                        onFreeFallDetected?()
                    }
                } else {
                    // We've just started reading sensor data while in free fall.
                    // Don't create a FreeFall event until this fall is over.
                    isInFreeFall = true
                }
            } else {
                isInFreeFall = false
                lastLandedTime = now
            }
            
        case _ as DidSleepResponse:
            owner?.disconnect(toy: self)
        
        case _ as SleepWarningResponse:
            core.send(PingCommand())
            
        default:
            break
        }
    }
    
    func toyCore(_ toyCore: Toy.ToyCore, didReceiveDeviceResponse response: DeviceCommandResponse) {
    }
    
}

//MARK: DriveRollable, Aimable
extension SpheroV1Toy: DriveRollable {
    
    public func roll(heading: Double, speed: Double) {
        let intSpeed = UInt8(speed.clamp(lowerBound: 0.0, upperBound: 255.0))
        let intHeading = UInt16(heading.positiveRemainder(dividingBy: 360.0))
        
        sendRollCommand(heading: intHeading, speed: intSpeed, rollType: .roll)
    }
    
    public func stopRoll(heading: Double) {
        let intHeading = UInt16(heading.positiveRemainder(dividingBy: 360.0))
        
        sendRollCommand(heading: intHeading, speed: 0, rollType: .stop)
    }
    
}

extension SpheroV1Toy: Aimable {
    
    public func startAiming() {
        setBackLed(brightness: 255.0)
    }
    
    public func stopAiming() {
        setBackLed(brightness: 0.0)
        sendHeadingCommand(heading: 0.0)
    }
    
    public func rotateAim(_ heading: Double) {
        sendHeadingCommand(heading: heading)
    }
    
}
