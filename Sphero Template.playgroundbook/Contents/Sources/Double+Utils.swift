//
//  Double+Utils.swift
//  SpheroSDK
//
//  Created by Anthony Blackman on 2017-03-15.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation

extension Double {
    
    public func clamp(lowerBound: Double, upperBound: Double) -> Double {
        var clamped = self
        clamped = max(lowerBound, clamped)
        clamped = min(upperBound, clamped)
        return clamped
    }
    
    public func positiveRemainder(dividingBy divisor: Double) -> Double {
        var remainder = truncatingRemainder(dividingBy: divisor)
        if self < 0.0 {
            remainder += divisor
        }
        return remainder
    }
    
    public static func random() -> Double {
        return Double(arc4random()) / Double(UInt32.max)
    }
    
    // Puts an angle in the range (-180,180]
    public func canonizedAngle() -> Double {
        var result = self.truncatingRemainder(dividingBy: 360.0)
        if result > 180.0 {
            result -= 360.0
        } else if result <= -180.0 {
            result += 360.0
        }
        return result
    }
    
}
