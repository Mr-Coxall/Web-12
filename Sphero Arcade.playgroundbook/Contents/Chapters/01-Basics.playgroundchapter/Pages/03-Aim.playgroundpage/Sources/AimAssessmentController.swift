//
//  AimAssessmentViewController.swift
//  spheroArcade
//
//  Created by Jeff Payan on 2017-03-22.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import PlaygroundSupport

public final class AimAssessmentController: AssessmentController {
    
    private struct Trip {
        var heading: Double?
        var startTime: TimeInterval?
        var speed: Double?
        var stopHeading: Double?
        var stopTime: TimeInterval?
    }
    
    private var awayTrip = Trip()
    private var returnTrip = Trip()
    private var rollCount = 0
    
    public override func assess(event: AssessmentEvent) -> PlaygroundPage.AssessmentStatus? {
        switch event.data {
        case let .roll(speed: speed, heading: heading):
            if rollCount == 0 {
                awayTrip.speed = speed
                awayTrip.heading = heading
                awayTrip.startTime = event.timestamp
            } else {
                returnTrip.speed = speed
                returnTrip.heading = heading
                returnTrip.startTime = event.timestamp
            }
        case let .stopRoll(heading: heading):
            if rollCount == 0 {
                awayTrip.stopHeading = heading
                awayTrip.stopTime = event.timestamp
                rollCount = rollCount + 1
            } else {
                returnTrip.stopHeading = heading
                returnTrip.stopTime = event.timestamp
            }
            
        case .userCodeFinished:
            guard let firstTripHeading = awayTrip.heading, let awayTripSpeed = awayTrip.speed, let awayTripStartTime = awayTrip.startTime, let awayTripStopTime = awayTrip.stopTime else {
                return .fail(hints: [NSLocalizedString("aim.fail.noStop", value: "You told Sphero to start rolling and then never told it to stop!  Try calling `stopRoll` to stop Sphero.", comment: "aim fail assessment, user never stopped rolling")], solution: nil)
            }
            
            guard let returnTripHeading = returnTrip.heading, let returnTripSpeed = returnTrip.speed, let returnTripStartTime = returnTrip.startTime  else {
                return .fail(hints: [NSLocalizedString("aim.fail.noReturn", value: "You didn't tell Sphero to come back! Try calling `roll` to return Sphero to you.", comment: "aim fail assessment, user never told Sphero to roll back")], solution: nil)
            }
            
            guard let returnTripStopTime = returnTrip.stopTime else {
                return .fail(hints: [NSLocalizedString("aim.fail.noStopOnReturn", value: "You need to stop on the way back! Try calling `stopRoll` to stop Sphero.", comment: "aim fail assessment, user never told Sphero to stop on the way back")], solution: nil)
            }
            
            let difference = abs((returnTripHeading - firstTripHeading) - 180.0)
            if difference > .ulpOfOne {
                return .fail(hints: [String.localizedStringWithFormat(NSLocalizedString("aim.fail.differentHeadings", value: "Sphero didn't come right back to you. Try adjusting the heading on your second `roll`. You were off by %.0f degrees!", comment: "aim fail assessment, user didnt use matching headings, %.0f is a difference in angles, i.e 30 degrees"), difference)], solution: nil)
            }
            
            let speedDifference = awayTripSpeed - returnTripSpeed
            if speedDifference > .ulpOfOne {
                return .fail(hints: [NSLocalizedString("aim.fail.differentSpeeds", value: "Sphero didn't come right back to you. Try adjusting the speed on your second `roll` to match the first!", comment: "aim fail assessment, user didn't use matching speeds")], solution: nil)
            }
            
            let awayTripTime = awayTripStopTime - awayTripStartTime
            let returnTripTime = returnTripStopTime - returnTripStartTime
            if returnTripTime < 0.1 {
                return .fail(hints: [NSLocalizedString("aim.fail.noWaitOnReturn", value: "Sphero stopped right after starting to roll. Try calling `wait` after Sphero starts rolling.",  comment: "aim fail assessment, user didn't use the `wait` function.")], solution: nil)
            }
            
            if 3.0 - awayTripTime > 0.1 || 3.0 - returnTripTime > 0.1 {
                return .fail(hints: [NSLocalizedString("aim.fail.differentDelays", value: "Your wait times didn't quite line up. Try adjusting your wait time to match the first one.",  comment: "aim fail assessment, user didn't use matching delays")], solution: nil)
            }
            
            return .pass(message: NSLocalizedString("aim.success.pageComplete", value: "### Congratulations! \nOn to the [next page](@next).", comment: "### is bold indicator, [] indicator that the text will be hyper linked, @(next) is URL link that is applied to [next page], localize 'Congratulations! \nOn to the next page'"))
            
        default:
            break
        }
        
        return nil
    }
    
}
