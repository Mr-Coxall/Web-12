//
//  ToyWrapper.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-16.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit

import PlaygroundSupport

public typealias CollisionListener = (_ collisionData: CollisionData) -> Void
public typealias SensorListener = (_ sensorData: SensorData) -> Void

public protocol ToyCommandListener {
    func setMainLed(color: UIColor)
    func setBackLed(brightness: Double)
    func setStabilization(state: SetStabilization.State)
    func setCollisionDetection(configuration: ConfigureCollisionDetection.Configuration)
    
    func roll(heading: Double, speed: Double)
    func stopRoll(heading: Double)
    func startAiming()
    func stopAiming()
    
    func enableSensors(sensorMask: SensorMask)
    func configureLocator(newX: Double, newY: Double, newYaw: Double)
}

// Default implementation of SPRKCommandListener with empty methods,
// so listeners can just override the methods they need.
open class ToyAdapter: ToyCommandListener {
    public init() {}
    
    open func setMainLed(color: UIColor) {}
    open func setBackLed(brightness: Double) {}
    open func setStabilization(state: SetStabilization.State) {}
    open func setCollisionDetection(configuration: ConfigureCollisionDetection.Configuration) {}
    
    open func roll(heading: Double, speed: Double) {}
    open func stopRoll(heading: Double) {}
    open func startAiming() {}
    open func stopAiming() {}
    
    open func enableSensors(sensorMask: SensorMask) {}
    open func configureLocator(newX: Double, newY: Double, newYaw: Double) {}
}

public class ToyWrapper: SpheroPlaygroundRemoteLiveViewProxyDelegate {
    
    private var commandListeners = [ToyCommandListener]()
    private var collisionListeners = [CollisionListener]()
    private var sensorListeners = [SensorListener]()

    public func addCommandListener(_ listener: ToyCommandListener) {
        commandListeners.append(listener)
    }
    
    public func addCollisionListener(_ listener: @escaping CollisionListener) {
        collisionListeners.append(listener)
    }

    public func addSensorListener(_ listener: @escaping SensorListener) {
        sensorListeners.append(listener)
    }

    public func setMainLed(color: UIColor) {
        commandListeners.forEach { $0.setMainLed(color: color) }
    }
    
    public func setBackLed(brightness: Double) {
        commandListeners.forEach { $0.setBackLed(brightness: brightness) }
    }
    
    public func setStabilization(state: SetStabilization.State) {
        commandListeners.forEach { $0.setStabilization(state: state) }
    }
    
    public func setCollisionDetection(configuration: ConfigureCollisionDetection.Configuration) {
        commandListeners.forEach { $0.setCollisionDetection(configuration: configuration) }
    }
    
    public func roll(heading: Double, speed: Double) {
        commandListeners.forEach { $0.roll(heading: heading, speed: speed) }
    }
    
    public func stopRoll(heading: Double) {
        commandListeners.forEach { $0.stopRoll(heading: heading) }
    }
    
    public func startAiming() {
        commandListeners.forEach { $0.startAiming() }
    }
    
    public func stopAiming() {
        commandListeners.forEach { $0.stopAiming() }
    }
    
    public func enableSensors(sensorMask: SensorMask) {
        commandListeners.forEach { $0.enableSensors(sensorMask: sensorMask) }
    }
    
    public func configureLocator(newX: Double, newY: Double, newYaw: Double) {
        commandListeners.forEach { $0.configureLocator(newX: newX, newY: newY, newYaw: newYaw)}
    }
    
    public func receive(_ message: PlaygroundValue) {
        guard let dict = message.dictValue() else { return }
        
        guard let typeIdValue = dict[MessageKeys.type] else { return }
        guard let typeId = MessageTypeId(value: typeIdValue) else { return }
        
        switch typeId {
        case .collisionDetected:
            guard let impactAccelerationDict = dict[MessageKeys.impactAcceleration]?.dictValue() else { return }
            guard let impactAccelerationX = impactAccelerationDict[MessageKeys.x]?.doubleValue() else { return }
            guard let impactAccelerationY = impactAccelerationDict[MessageKeys.y]?.doubleValue() else { return }
            guard let impactAccelerationZ = impactAccelerationDict[MessageKeys.z]?.doubleValue() else { return }
            
            let impactAcceleration = CollisionAcceleration(x: impactAccelerationX, y: impactAccelerationY, z: impactAccelerationZ)
            
            guard let impactAxisDict = dict[MessageKeys.impactAxis]?.dictValue() else { return }
            guard let impactAxisX = impactAxisDict[MessageKeys.x]?.boolValue() else { return }
            guard let impactAxisY = impactAxisDict[MessageKeys.y]?.boolValue() else { return }
            
            let impactAxis = CollisionAxis(x: impactAxisX, y: impactAxisY)
            
            guard let impactPowerDict = dict[MessageKeys.impactPower]?.dictValue() else { return }
            guard let impactPowerX = impactPowerDict[MessageKeys.x]?.doubleValue() else { return }
            guard let impactPowerY = impactPowerDict[MessageKeys.y]?.doubleValue() else { return }
            
            let impactPower = CollisionPower(x: impactPowerX, y: impactPowerY)
            
            guard let impactSpeed = dict[MessageKeys.impactSpeed]?.doubleValue() else { return }
            guard let timestamp: TimeInterval = dict[MessageKeys.timestamp]?.doubleValue() else { return }
            
            let data = CollisionData(impactAcceleration: impactAcceleration, impactAxis: impactAxis, impactPower: impactPower, impactSpeed: impactSpeed, timestamp: timestamp)
            
            collisionListeners.forEach { $0(data) }
            
        case .sensorData:
            var locator: LocatorSensorData?
            var orientation: AttitudeSensorData?
            var gyro: GyroscopeSensorData?
            var accelerometer: AccelerometerSensorData?
            
            if let locatorDict = dict[MessageKeys.locator]?.dictValue() {
                locator = LocatorSensorData()
                if let positionDict = locatorDict[MessageKeys.position]?.dictValue() {
                    locator?.position = TwoAxisSensorData<Double>()
                    locator?.position?.x = positionDict[MessageKeys.x]?.doubleValue()
                    locator?.position?.y = positionDict[MessageKeys.y]?.doubleValue()
                }
                if let velocityDict = locatorDict[MessageKeys.velocity]?.dictValue() {
                    locator?.velocity = TwoAxisSensorData<Double>()
                    locator?.velocity?.x = velocityDict[MessageKeys.x]?.doubleValue()
                    locator?.velocity?.y = velocityDict[MessageKeys.y]?.doubleValue()
                }
            }
            if let orientationDict = dict[MessageKeys.orientation]?.dictValue() {
                orientation = AttitudeSensorData()
                if let x = orientationDict[MessageKeys.x]?.intValue() {
                    orientation?.yaw = x
                }
                if let y = orientationDict[MessageKeys.y]?.intValue() {
                    orientation?.pitch = y
                }
                if let z = orientationDict[MessageKeys.z]?.intValue() {
                    orientation?.roll = z
                }
            }
            if let gyroDict = dict[MessageKeys.gyro]?.dictValue() {
                gyro = GyroscopeSensorData()
                if let filteredDict = gyroDict[MessageKeys.filtered]?.dictValue() {
                    gyro?.rotationRate = ThreeAxisSensorData<Int>()
                    gyro?.rotationRate?.x = filteredDict[MessageKeys.x]?.intValue()
                    gyro?.rotationRate?.y = filteredDict[MessageKeys.y]?.intValue()
                    gyro?.rotationRate?.z = filteredDict[MessageKeys.z]?.intValue()
                }
                if let rawDict = gyroDict[MessageKeys.raw]?.dictValue() {
                    gyro?.rawRotation = ThreeAxisSensorData<Int>()
                    gyro?.rawRotation?.x = rawDict[MessageKeys.x]?.intValue()
                    gyro?.rawRotation?.y = rawDict[MessageKeys.y]?.intValue()
                    gyro?.rawRotation?.z = rawDict[MessageKeys.z]?.intValue()
                }
            }
            if let accelerometerDict = dict[MessageKeys.accelerometer]?.dictValue() {
                accelerometer = AccelerometerSensorData()
                if let filteredDict = accelerometerDict[MessageKeys.filtered]?.dictValue() {
                    accelerometer?.filteredAcceleration = ThreeAxisSensorData<Double>()
                    accelerometer?.filteredAcceleration?.x = filteredDict[MessageKeys.x]?.doubleValue()
                    accelerometer?.filteredAcceleration?.y = filteredDict[MessageKeys.y]?.doubleValue()
                    accelerometer?.filteredAcceleration?.z = filteredDict[MessageKeys.z]?.doubleValue()
                }
                if let rawDict = accelerometerDict[MessageKeys.raw]?.dictValue() {
                    accelerometer?.rawAcceleration = ThreeAxisSensorData<Int>()
                    accelerometer?.rawAcceleration?.x = rawDict[MessageKeys.x]?.intValue()
                    accelerometer?.rawAcceleration?.y = rawDict[MessageKeys.y]?.intValue()
                    accelerometer?.rawAcceleration?.z = rawDict[MessageKeys.z]?.intValue()
                }
            }
            
            let data = SensorData(locator: locator, orientation: orientation, gyro: gyro, accelerometer: accelerometer)
            sensorListeners.forEach { $0(data) }
            
        default:
            break
        }
    }
    
    public func remoteLiveViewProxyConnectionClosed(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy) {
        
    }
    
}
