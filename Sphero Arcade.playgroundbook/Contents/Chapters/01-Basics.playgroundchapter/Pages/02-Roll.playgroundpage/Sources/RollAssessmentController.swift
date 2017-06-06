//
//  LiveView.swift
//  spheroArcade
//
//  Created by Jordan Hesse on 2017-03-22.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation

import PlaygroundSupport

public final class RollAssessmentController: AssessmentController {
    
    private var rollStartTime: TimeInterval?
    private var rollStopTime: TimeInterval?
    
    private var rollSpeed: Double?
    
    public override func assess(event: AssessmentEvent) -> PlaygroundPage.AssessmentStatus? {
        switch event.data {
        case let .roll(speed: speed, heading: _):
            rollStartTime = rollStartTime ?? event.timestamp
            rollSpeed = speed
            
        case .stopRoll(heading: _):
            if rollStartTime != nil {
                rollStopTime = rollStopTime ?? event.timestamp
            }
            
        case .userCodeFinished:
            guard let startTime = rollStartTime,
                let speed = rollSpeed, let stopTime = rollStopTime else {
                    //this should never happen, as this is hardcoded in the contents
                    return nil
            }
            
            guard speed > 0.0 else {
                return .fail(hints: [NSLocalizedString("roll.fail.zeroSpeed", value: "Sphero didn't move! Try using a higher speed in your `roll` function.", comment: "zero speed fail assessment")], solution: nil)
            }
            
            let waitTime = stopTime - startTime
            
            guard waitTime > .ulpOfOne else {
                return .fail(hints: [NSLocalizedString("roll.fail.zeroDelay", value: "Sphero didn't wait! Try using a longer delay in your `wait` function ", comment: "zero delay fail assessment")], solution: nil)
            }
            
            if abs(speed - 50.0) < 0.5 {
                return .fail(hints: [NSLocalizedString("roll.success.changeSpeed", value: "Great, you ran your code! Now try changing the speed from `50.0` to another value and run the program again.", comment: "first roll success message, increase robot speed and run program again")], solution: nil)
            }
            
            if abs(waitTime - 3.0) < 0.1 {
                return .fail(hints: [NSLocalizedString("roll.success.changeDelay", value: "Good job, you changed the speed! Now try changing the delay time from `3.0` to another value and run the program again.", comment: "second roll success message, change wait function delay and run again")], solution: nil)
            }
            
            return .pass(message: NSLocalizedString("roll.success.pageComplete", value: "### Congratulations! \nOn to the [next page](@next).", comment: "### is bold indicator, [] indicator that the text will be hyper linked, @(next) is URL link that is applied to [next page], localize 'Congratulations! \nOn to the next page'"))
            
        default:
            break
        }
        
        return nil
    }
    
}
