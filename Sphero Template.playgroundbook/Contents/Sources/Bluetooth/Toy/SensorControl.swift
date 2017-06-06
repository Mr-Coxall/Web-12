//
//  SensorControl.swift
//  SpheroSDK
//
//  Created by Jeff Payan on 2017-03-14.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation

protocol SensorControlProvider {
    var sensorControl: SensorControl { get }
}

public struct SensorMask: OptionSet {
    public let rawValue: UInt64
    
    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
    
    public static let off = SensorMask(rawValue: 0)
    public static let gyroZFiltered = SensorMask(rawValue: 2 << 9)
    public static let gyroYFiltered = SensorMask(rawValue: 2 << 10)
    public static let gyroXFiltered = SensorMask(rawValue: 2 << 11)
    public static let accelerometerZFiltered = SensorMask(rawValue: 2 << 12)
    public static let accelerometerYFiltered = SensorMask(rawValue: 2 << 13)
    public static let accelerometerXFiltered = SensorMask(rawValue: 2 << 14)
    public static let imuYawAngleFiltered = SensorMask(rawValue: 2 << 15)
    public static let imuRollAngleFiltered = SensorMask(rawValue: 2 << 16)
    public static let imuPitchAngleFiltered = SensorMask(rawValue: 2 << 17)
    public static let gyroZRaw = SensorMask(rawValue: 2 << 21)
    public static let gyroYRaw = SensorMask(rawValue: 2 << 22)
    public static let gyroXRaw = SensorMask(rawValue: 2 << 23)
    public static let accelerometerZRaw = SensorMask(rawValue: 2 << 24)
    public static let accelerometerYRaw = SensorMask(rawValue: 2 << 25)
    public static let accelerometerXRaw = SensorMask(rawValue: 2 << 26)
    public static let accelerometerRaw =  SensorMask(rawValue: accelerometerZRaw.rawValue | accelerometerYRaw.rawValue | accelerometerXRaw.rawValue)
    public static let locatorX = SensorMask(rawValue: 2 << 58)
    public static let locatorY = SensorMask(rawValue: 2 << 57)
    public static let velocityX = SensorMask(rawValue: 2 << 55)
    public static let velocityY = SensorMask(rawValue: 2 << 54)
    public static let gyroFilteredAll = SensorMask(rawValue: gyroZFiltered.rawValue | gyroYFiltered.rawValue | gyroXFiltered.rawValue)
    public static let imuAnglesFilteredAll = SensorMask(rawValue: imuYawAngleFiltered.rawValue | imuRollAngleFiltered.rawValue | imuPitchAngleFiltered.rawValue)
    public static let accelerometerFilteredAll = SensorMask(rawValue: accelerometerZFiltered.rawValue | accelerometerYFiltered.rawValue | accelerometerXFiltered.rawValue)
    public static let locatorAll = SensorMask(rawValue: locatorX.rawValue | locatorY.rawValue | velocityX.rawValue | velocityY.rawValue)
}

class SensorControl {
    final let intervalToHz = 1000
    
    func enable(sensors sensorMask: SensorMask) {
        let intervalInSeconds = Double(interval) / Double(intervalToHz)
        let streamingRate = Int(1.0/intervalInSeconds)
        
        toyCore?.send(EnableSensors(sensorMask: sensorMask, streamingRate: streamingRate))
    }
    
    func disable() {
        toyCore?.send(EnableSensors(sensorMask: .off, streamingRate: 0))
    }
    
    weak var toyCore: Toy.ToyCore?
    public init(toyCore: Toy.ToyCore) {
        self.toyCore = toyCore
        self.toyCore?.addAsyncListener(self)
    }
    
    var interval: Int = 250
    
    var onDataReady: ((_ sensorData: SensorData) -> Void)?
}

extension SensorControl: ToyCoreAsyncListener {
    
    func toyCore(_ toyCore: Toy.ToyCore, didReceiveAsyncResponse response: AsyncCommandResponse) {
        guard let sensorData = response as? SensorDataCommandResponse else { return }
        onDataReady?(sensorData)
    }
    
    func toyCore(_ toyCore: Toy.ToyCore, didReceiveDeviceResponse response: DeviceCommandResponse) {
    }
    
}
