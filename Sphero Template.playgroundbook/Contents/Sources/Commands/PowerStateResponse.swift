//
//  PowerStateResponse.swift
//  SpheroSDK
//
//  Created by Jeff Payan on 2017-05-02.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation

public struct PowerStateResponse: DeviceCommandResponse {
    public let batteryVoltage: Double
    
    public init(_ data: Data) {
        let bigByte = UInt16(data[2] as UInt8) << 8
        let littleByte = UInt16(data[3] as UInt8)
        self.batteryVoltage = Double((bigByte + littleByte)) / 100.0
    }
}
