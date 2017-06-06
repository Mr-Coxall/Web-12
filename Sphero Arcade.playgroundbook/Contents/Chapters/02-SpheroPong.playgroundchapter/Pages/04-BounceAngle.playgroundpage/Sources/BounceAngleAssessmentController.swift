//
//  VolleyAssessmentController.swift
//  spheroArcade
//
//  Created by Jeff Payan on 2017-03-29.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import PlaygroundSupport

public final class BounceAngleAssessmentController: AssessmentController {
    
    private var inCollisionHandler = false
    private var collisionHeading: Double?
    private var impactAccelerationX: Double?
    private var randomNumber: Int?
    
    public override func assess(event: AssessmentEvent) -> PlaygroundPage.AssessmentStatus? {
        switch event.data {
        case let .roll(speed: _, heading: heading):
            if inCollisionHandler {
                collisionHeading = heading
            }
            break
            
        case let .collision(data: data):
            impactAccelerationX = data.impactAcceleration.x
            inCollisionHandler = true
            break
            
        default:
            break
        }
        
        return nil
    }
    
    public func assessAfterCollision(_ collisionData: CollisionData) {
        guard let collisionHeading = collisionHeading else {
            makeAssessment(status: .fail(hints: [NSLocalizedString("bounceAngle.fail.noRoll", value: "You didn't tell Sphero to roll after the collision! Try calling the `roll` function.", comment: "assessment fail, user didn't start a roll after a collision event")], solution: nil))
            return
        }
        
        guard randomNumber != nil else {
            makeAssessment(status: .fail(hints: [NSLocalizedString("bounceAngle.fail.noRandomNumber", value: "You didn't use the `randomNumber` function. Try using `randomNumber` to generate the random portion of the bounce angle. ", comment: "assessment fail, user didn't call the random number function")], solution: nil))
            return
        }
        
        //did they choose some factor that was way too large
        if collisionHeading < 100 || collisionHeading > 270 {
            makeAssessment(status: .fail(hints: [NSLocalizedString("bounceAngle.fail.angleTooLarge", value: "Woah, Sphero is bouncing back at some crazy angles! Try reducing the range of your random bounded values.", comment: "assessment fail, user used an angle that was too large")], solution: nil))
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0, execute: {
            self.makeAssessment(status: .pass(message: NSLocalizedString("bounceAngle.success.pageComplete", value: "### Congratulations! \nOn to the [next page](@next).", comment: "### is bold indicator, [] indicator that the text will be hyper linked, @(next) is URL link that is applied to [next page], localize 'Congratulations! \nOn to the next page'")))
        })
    }
    
    public func assess(randomlyGeneratedNumber: Int) {
        randomNumber = randomlyGeneratedNumber
    }

}
