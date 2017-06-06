//
//  VolleyAssessmentController.swift
//  spheroArcade
//
//  Created by Jeff Payan on 2017-03-29.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import PlaygroundSupport
import UIKit

public final class VolleyAssessmentController: AssessmentController {
    
    private var initialRollStartTime: TimeInterval?
    private var lastRollHeading: Double?
    private var initialrollStopTime: TimeInterval?
    private var collisionRollStartTime: TimeInterval?
    private var collisionRollHeading: Double?
    private var firstLEDColor: UIColor?
    
    private var didSetMainLED = false
    private var collisionCount = 0
    private var inCollisionHandler = false
    
    public override func assess(event: AssessmentEvent) -> PlaygroundPage.AssessmentStatus? {
        switch event.data {
        case let .roll(speed: _, heading: heading):
            if inCollisionHandler {
                collisionRollStartTime = event.timestamp
                
                if let lastRollHeading = lastRollHeading {
                    //check the difference between the last angle we recorded and this new one. Since it can be (-30, 30) on 0 and 180, check the minimum difference
                    let difference: Double = abs((lastRollHeading - heading).canonizedAngle())
                    if difference < 120.0 {
                        makeAssessment(status: .fail(hints:[NSLocalizedString("volley.fail.wrongReturnAngle", value: "Sphero needs to roll back towards the opposing player. Check to make sure your `currentPlayer` variable is updated and the base angle you passed in to your `volley` function is correct.", comment: "volley assessment fail, user didn't send the Sphero back towards the other player.")], solution: nil))
                        return nil
                    }
                }
                
                lastRollHeading = heading
            } else {
                lastRollHeading = heading
                initialRollStartTime = event.timestamp
            }
            break
            
        case .collision(data: _):
            didSetMainLED = false
            inCollisionHandler = true
            collisionCount += 1
            if collisionCount > 3 {
                makeAssessment(status: .pass(message: NSLocalizedString("volley.success.pageComplete", value: "### Congratulations! \nOn to the [next page](@next).", comment: "### is bold indicator, [] indicator that the text will be hyper linked, @(next) is URL link that is applied to [next page], localize 'Congratulations! \nOn to the next page'")))
                return nil
            }
            
        case let .mainLed(color: color):
            if let ledColor = firstLEDColor {
                if color.isEqual(ledColor) {
                    makeAssessment(status: .fail(hints:[NSLocalizedString("volley.fail.noLEDChange", value: "You didn't update Sphero's color for the new player. Make sure to change the color of Sphero based on the value of `currentPlayer`.", comment: "volley assessment fail, user didn't update Sphero's color properly.")], solution: nil))
                    return nil
                }
            }
            
            firstLEDColor = color
            didSetMainLED = true
            break
            
        case .userCodeFinished:
            if initialRollStartTime == nil {
                return .fail(hints:[NSLocalizedString("volley.fail.noRoll", value: "You didn't tell Sphero to start rolling. Try calling the `roll` function.", comment: "volley assessment fail, user never called the roll function to start Sphero rolling")], solution: nil)
            }
            
            return nil
            
        default:
            break
        }
        
        return nil
    }
    
    public func assessAfterCollision(_ collisionData: CollisionData) {
        if !didSetMainLED {
            makeAssessment(status: .fail(hints:[NSLocalizedString("volley.fail.noLEDSet", value: "You didn't set Sphero's main LED color in your collision handler! Try calling the `setMainLed` function.",  comment: "volley assessment fail, user didn't set Sphero's color at all. 'collision handler' is describing the function that handles when Sphero runs into something")], solution: nil))
            return
        }
        
        if collisionRollStartTime == nil {
            makeAssessment(status: .fail(hints:[NSLocalizedString("volley.fail.noRollBack", value: "You didn't tell Sphero to roll back after the collision! Try calling the `roll` function in your collision handler.", comment: "volley assessment fail, user didn't provide a roll function to tell Sphero to roll after a collision. 'collision handler' is describing the function that handles when Sphero runs into something")], solution: nil))
            return
        }
    }
    
}


