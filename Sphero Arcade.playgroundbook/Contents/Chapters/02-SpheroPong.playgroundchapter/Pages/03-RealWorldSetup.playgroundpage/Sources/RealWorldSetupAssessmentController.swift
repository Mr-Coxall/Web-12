//
//  HeadingAssessmentController.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-22.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import PlaygroundSupport
import Foundation

public final class RealWorldSetupAssessmentController: AssessmentController {
    
    private var rollStartTime: Double?
    private var stopStartTime: Double?
    
    private var rollSpeed: Double?
    private var userCodeFinished: Bool = false
    
    public override func assess(event: AssessmentEvent) -> PlaygroundPage.AssessmentStatus?  {
        
        switch event.data {
        case let .roll(speed: speed, heading: _):
            rollStartTime = event.timestamp
            rollSpeed = speed
            break
            
        case .stopRoll(heading: _):
            stopStartTime = event.timestamp
            
            break
            
        case .userCodeFinished:
            guard let _ = rollStartTime, let speed = rollSpeed else {
                return .fail(hints:[NSLocalizedString("realWorld.fail.noRoll", value: "You didn't tell Sphero to start rolling. Try calling the `roll` function.", comment: "assessment failure, Sphero was never told to start rolling. ")], solution:nil)
            }
            
            guard let _ = stopStartTime else {
                makeAssessment(status: .fail(hints: [NSLocalizedString("realWorld.fail.noStop", value: "You didn't tell Sphero to stop rolling. Try calling the `stopRoll` function.", comment: "assessment failure, Sphero was never told to stop rolling.")], solution: nil))
                return nil
            }
            
            if speed < 50.0 {
                return .fail(hints:[NSLocalizedString("realWorld.fail.tooSlow", value: "Sphero needs more speed to play Pong! Try using a speed of at least 50.0 in your `roll` function", comment: "assessment failure, user told Sphero to roll too slowly, 50 is the minimum speed")], solution:nil)
            }
            
            userCodeFinished = true
            
            return nil
        default:
            break
        }
        return nil
    }
    
    public func locatorDidUpdate(_ locatorY: Double, distanceThreshold: Double) {
        if userCodeFinished {
            if distanceThreshold < 150.0 {
                makeAssessment(status: .fail(hints: [NSLocalizedString("realWorld.fail.boardTooSmall", value: "Your game area is too small! Set `distanceApart` to be at least 150 cm.", comment: "real world page assessment failure, user tried to set the `distanceApart` variable to something less than 150 cm")], solution: nil))
                return
            }
            
            if distanceThreshold > 250.0 {
                makeAssessment(status: .fail(hints: [NSLocalizedString("realWorld.fail.boardTooBig", value: "Your game area is too big! Set `distanceApart` to be at most 250 cm.", comment: "real world page assessment failure, user tried to set the `distanceApart` variable to something more than 250 cm")], solution: nil))
                return
            }
            
            let difference = abs(distanceThreshold - locatorY)
            if difference > (distanceThreshold * 0.2) {
                makeAssessment(status: .fail(hints: [String(format: NSLocalizedString("realWorld.fail.distanceFail", value: "You were aiming for %.1f cm but Sphero rolled %.1f cm. Try adjusting your `roll` speed or delay to get closer to your goal!", comment: "real world page assessment fail, user didn't reach the target distance. first %.1f is the target distance in cm the second %.1f is how far the robot rolled in cm."), distanceThreshold, locatorY)], solution: nil))
                return
            }
            
            makeAssessment(status: .pass(message: NSLocalizedString("realWorld.success.pageComplete", value: "### Nice work! \nYour game area is set up. You can adjust the size of your game area or continue on to the [next page](@next).", comment: "### is bold indicator, [] indicator that the text will be hyper linked, @(next) is URL link that is applied to [next page], localize 'Nice work! Your game area is set up. You can adjust the size of your game area or continue on to the next page.'")))
        }
    }
    
}
