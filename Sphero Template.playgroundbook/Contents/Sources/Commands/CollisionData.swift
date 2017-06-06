//
//  CollisionData.swift
//  SpheroSDK
//
//  Created by Anthony Blackman on 2017-03-13.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation

public struct CollisionAcceleration {
    public var x: Double
    public var y: Double
    public var z: Double
}

public struct CollisionAxis {
    public var x: Bool
    public var y: Bool
}

public struct CollisionPower {
    public var x: Double
    public var y: Double
}

private func accelerometerDataToGs(bytes: ArraySlice<UInt8>) -> Double {
    let intData = intFromBytes(bytes: bytes)
    
    return Double(Int16(truncatingBitPattern: intData)) / 4096.0
}

private func intFromBytes(bytes: ArraySlice<UInt8>) -> Int {
    var result = 0
    for byte in bytes {
        result *= 256
        result += Int(byte)
    }
    
    return result
}

public struct CollisionDataCommandResponse: AsyncCommandResponse {
    private static let DataLength = 16

    public var impactAcceleration: CollisionAcceleration
    public var impactAxis: CollisionAxis
    public var impactPower: CollisionPower
    public var impactSpeed: Double
    public var timestamp: TimeInterval
    
    public init(
        impactAcceleration: CollisionAcceleration,
        impactAxis: CollisionAxis,
        impactPower: CollisionPower,
        impactSpeed: Double,
        timestamp: TimeInterval
    ) {
        self.impactAcceleration = impactAcceleration
        self.impactAxis = impactAxis
        self.impactPower = impactPower
        self.impactSpeed = impactSpeed
        self.timestamp = timestamp
    }

    public init?(data: [UInt8]) {
        if data.count == CollisionDataCommandResponse.DataLength {
            let impactAccelX = accelerometerDataToGs(bytes: data[0...1])
            let impactAccelY = accelerometerDataToGs(bytes: data[2...3])
            let impactAccelZ = accelerometerDataToGs(bytes: data[4...5])
            
            self.impactAcceleration = CollisionAcceleration(x: impactAccelX, y: impactAccelY, z: impactAccelZ)
            
            let impactMask = data[6]
            let impactAxisX = impactMask & 0x01 != 0
            let impactAxisY = impactMask & 0x02 != 0
            
            self.impactAxis = CollisionAxis(x: impactAxisX, y: impactAxisY)
            
            let impactPowerX = Double(intFromBytes(bytes: data[7...8]))
            let impactPowerY = Double(intFromBytes(bytes: data[9...10]))
            self.impactPower = CollisionPower(x: impactPowerX, y: impactPowerY)
            
            self.impactSpeed = Double(data[11]) / 255.0
            
            self.timestamp = Double(intFromBytes(bytes: data[12...15])) / 1000.0
        } else {
            return nil
        }
    }
    
    public var impactAngle: Double {
        get {
            let angleRadians = atan2(-impactAcceleration.x, -impactAcceleration.y)
            let angleDegrees = angleRadians * 180.0 / .pi
            
            return angleDegrees
        }
    }
}

/// Data describing the collision.
public typealias CollisionData = CollisionDataCommandResponse
