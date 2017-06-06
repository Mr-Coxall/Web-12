//
//  HeadingAssessmentController.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-22.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import PlaygroundSupport
import Foundation

public class CollisionAssessmentController: AssessmentController {
    
    var didSetMainLED = false
    
    public override func assess(event: AssessmentEvent) -> PlaygroundPage.AssessmentStatus?  {
        switch event.data {
        case .mainLed(_):
            didSetMainLED = true
            
        default:
            break
        }
        
        return nil
    }
    
    public func assessAfterCollision(_ collisionData: CollisionData) {
        if !didSetMainLED {
            self.makeAssessment(status: .fail(hints: [NSLocalizedString("collision.fail.noLEDChange", value: "Your Sphero detected a collision, but you didn't set Sphero's LED color. Try calling `setMainLed(color: .red)` to set the color.", comment: "collision fail assessment, Sphero detected a collision, but user failed to update Spheros LED color.")], solution: nil))
        } else {
            self.makeAssessment(status: .pass(message: NSLocalizedString("collision.success.pageComplete", value: "### Good Going! \nYour Sphero detected a collision, and you set the LED color!\n\nYou're all set for the [next chapter](@next).", comment: "### is bold indicator, [] indicator that the text will be hyper linked, @(next) is URL link that is applied to [next page], localize 'Good Going! \nYour Sphero detected a collision, and you set the LED color!\n\nYou're all set for next page'")))
        }
    }
}
