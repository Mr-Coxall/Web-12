//
//  HeadingAssessmentController.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-22.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import PlaygroundSupport
import Foundation

public class HeadingAssessmentController: AssessmentController {

    var lastRollEventTime: TimeInterval?
    
    var isRolling = false
    
    var firstRollSpeed: Double?
    var firstRollTime: TimeInterval?
    
    var lastRollHeading: Double?
    
    var isFirstAngleClockwise: Bool?
    
    var successfulLineCount = 0
    
    var didMakeAssessment = false
    
    public override func assess(event: AssessmentEvent) -> PlaygroundPage.AssessmentStatus? {
        switch event.data {
        case let .roll(speed: speed, heading: heading):
            if isRolling {
                return .fail(hints: [NSLocalizedString("heading.fail.roundedCorners", value: "Make sure you're stopping Sphero between each time you tell Sphero to roll, otherwise your square won't have sharp corners. You can stop Sphero by calling `stopRoll`.",  comment: "heading fail assessment, user needs to call the `stopRoll` function between roll commands, otherwise their square will have rounded corners")], solution: nil)
            }
            
            if let firstRollSpeed = firstRollSpeed {
                if speed != firstRollSpeed {
                    return .fail(hints: [NSLocalizedString("heading.fail.differentSpeeds", value: "Make sure you're using the same speed for each side of the square. Otherwise you might end up with a rectangle!", comment: "heading fail assessment, user needs to use matching speeds in their roll functions, otherwise their square will be a rectangle")], solution: nil)
                }
            } else {
                firstRollSpeed = speed
            }
            
            if let lastRollHeading = lastRollHeading {
                let cornerAngle = (heading - lastRollHeading).canonizedAngle()
                
                let absCornerAngle: Double = abs(cornerAngle)
                let difference: Double = abs(absCornerAngle - 90.0)
                if difference > 1.0 {
                    return .fail(hints: [NSLocalizedString("heading.fail.differentCornerAngles", value: "All the angles in a square are 90 degrees. Make sure that each time you tell Sphero to roll, you change the heading by 90 degrees.", comment: "heading fail assessment, user didn't use 90 degree corners for their square")], solution: nil)
                }
                
                let isClockwise = cornerAngle < 0
                
                if let isFirstAngleClockwise = isFirstAngleClockwise {
                    if isClockwise != isFirstAngleClockwise {
                        return .fail(hints: [NSLocalizedString("heading.fail.differentDirections", value: "Make sure you're turning the robot the same direction each time. Try increasing the heading by 90 degrees each time you call `roll`.", comment: "heading fail assessment, user didn't turn the robot in the same direction for each corner. must add 90 degrees for each roll function")], solution: nil)
                    }
                } else {
                    isFirstAngleClockwise = isClockwise
                }
            }
            
            if let lastTime = lastRollEventTime {
                let waitTime = event.timestamp - lastTime
                if waitTime < 0.1 {
                    return .fail(hints: [NSLocalizedString("heading.fail.noStopWait", value: "You told Sphero to start rolling immediately after stopping it. Try waiting after you tell Sphero to stop rolling, to give your square sharp corners.", comment: "heading fail assessment, user didn't add a wait function after stopping. Sphero takes some time to come to a complete stop.")], solution: nil)
                }
            }
            
            isRolling = true
            
            lastRollHeading = heading
            
            lastRollEventTime = event.timestamp
            
        case .stopRoll(heading: _):
            if !isRolling {
                // Ignore extra stopRoll calls
                return nil
            }
            
            if let startTime = lastRollEventTime {
                let waitTime = event.timestamp - startTime
                if waitTime < 0.1 {
                    return .fail(hints: [NSLocalizedString("heading.fail.noRollWait", value: "You told Sphero to stop rolling immediately after starting it. Try waiting after you tell Sphero to start rolling. You can wait for one second with `wait(for: 1.0)`", comment: "heading fail assessment, user didn't add a wait function after rolling. Calling stop right after roll will cause Sphero to not move at all.")], solution: nil)
                }
                
                if let firstRollTime = firstRollTime {
                    let difference: Double = abs(waitTime - firstRollTime)
                    if difference > 0.1 {
                        return .fail(hints: [NSLocalizedString("heading.fail.differentDelays", value: "You waited for different times on different edges of the square. Try using the same time or else you might end up with a rectangle!", comment: "heading fail assessment, user used different delays in their roll commands for the sides of the square. need equal delays to make a square")], solution: nil)
                    }
                } else {
                    firstRollTime = waitTime
                }
            }
            
            successfulLineCount += 1
            
            if successfulLineCount == 4 {
                return .pass(message: NSLocalizedString("heading.success.pageComplete", value: "### Congratulations! \nYour Sphero rolled in a square! \nTry the [next page](@next).", comment: "### is bold indicator, [] indicator that the text will be hyper linked, @(next) is URL link that is applied to [next page], localize 'Congratulations! \nYour Sphero rolled in a square! \nTry the next page'"))
            }
            
            isRolling = false
            
            lastRollEventTime = event.timestamp
            
        case .userCodeFinished:
            
            if lastRollEventTime == nil {
                // roll(...) was never called.
                return .fail(hints: [NSLocalizedString("heading.fail.noRoll", value: "Try telling Sphero to roll with `roll(heading: 0.0, speed: 50.0)`",  comment: "heading fail assessment, user never called the roll function to start their Sphero")], solution: nil)
            }
            
            if isRolling {
                return .fail(hints: [NSLocalizedString("heading.fail.noStop", value: "You forgot to tell your Sphero to stop rolling. It will keep rolling forever!  Try calling `stopRoll` at the end of your code.", comment: "heading fail assessment, user never told their Sphero to stop rolling after calling the roll function")], solution: nil)
            }
            
            return .fail(hints: [NSLocalizedString("heading.fail.notASquare", value: "Your code ran without any problems, but you didn't finish making a square. Try adding another more calls to `roll`.", comment: "heading fail assessment, code had no mistakes but they didn't finish all four sides of the square")], solution: nil)
            
        default:
            break
        }
        
        return nil
    }
}
