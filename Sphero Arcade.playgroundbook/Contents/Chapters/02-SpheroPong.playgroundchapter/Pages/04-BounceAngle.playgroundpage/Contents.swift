//#-hidden-code
//
//  Contents.swift
//  spheroArcade
//
//  Created by Jordan Hesse on 2017-03-17.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//
//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
 **Goal:** After a collision, make Sphero bounce back at a random angle.
 
 Now that you've set up your playing area, you'll write the code to return the ball at a random angle. This makes the ball more unpredictable. You'll use the `randomNumber` function to offset the `baseAngle` by a random amount.
 ````
 let randomAngle = randomNumber(min: -30, max: 30)
 ````
 In Sphero Pong there are no boundaries to the playing area, so you can't use just any random number -- the game would be too hard. In the example above, `randomNumber` will return a value between `-30` and `30`. The larger the range, the more unpredictable the bounce angle will be.
 
 Implement the `volley` function by calling `roll` with the computed heading.
 */
//#-hidden-code
import Foundation
import PlaygroundSupport

let assessmentController = BounceAngleAssessmentController()

func randomNumber(min: Int, max: Int) -> Int {
    let returnValue = Int(arc4random_uniform(UInt32(max - min))) + min
    
    var randomNumberDict = [String:PlaygroundValue]()
    
    randomNumberDict[MessageKeys.type] = MessageTypeId.randomNumberGenerated.playgroundValue()
    randomNumberDict[MessageKeys.randomNumberMinimum] = .integer(min)
    randomNumberDict[MessageKeys.randomNumberMaximum] = .integer(max)
    randomNumberDict[MessageKeys.randomNumberGenerated] = .integer(returnValue)
    
    PlaygroundHelpers.sendMessageToLiveView(.dictionary(randomNumberDict))
    
    assessmentController.assess(randomlyGeneratedNumber: returnValue)
    
    return returnValue
}
//#-end-hidden-code
//#-editable-code
//#-code-completion(everything, hide)
//#-code-completion(identifier, show, randomNumber(min:max:), roll(heading:speed:), baseAngle, +, -, =)
//#-code-completion(currentmodule, show)
//#-code-completion(identifier, hide, onCollision(data:), internalOnCollision(data:), userCode_BounceAngle(), assessmentController)
func volley(baseAngle: Int) {
    
}
//#-end-editable-code
func onCollision(data: CollisionData) {
    stopRoll()
    wait(for: 1.0)
    volley(baseAngle: 180)
}

//#-hidden-code
private func internalOnCollision(data: CollisionData) {
    setCollisionDetection(configuration: .disabled)
    onCollision(data: data)
    setCollisionDetection(configuration: .enabled)
    assessmentController.assessAfterCollision(data)
}

func userCode_BounceAngle() {
    addCollisionListener(internalOnCollision)
    setCollisionDetection(configuration: .enabled)
    roll(heading: 0, speed: 100)
}

PlaygroundPage.current.needsIndefiniteExecution = true
setupContent(assessment: assessmentController, userCode: userCode_BounceAngle)
//#-end-hidden-code
