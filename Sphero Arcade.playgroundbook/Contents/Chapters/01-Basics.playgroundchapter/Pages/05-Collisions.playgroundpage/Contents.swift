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
 **Goal:** Change Sphero's color when it collides with another object.
 
 When Sphero detects an impact it calls the function `onCollision`. You can use this function to run code in response to the impact.
 
 You can use the `setMainLed` function to change Sphero's color. 
 
 Add your code to update Sphero's color in the `onCollision` function below.
 */
//#-hidden-code
import Foundation
import PlaygroundSupport

let assessmentController = CollisionAssessmentController()

//#-end-hidden-code
//#-editable-code
//#-code-completion(everything, hide)
//#-code-completion(identifier, show, setMainLed(color:), red, roll(heading:speed:), wait(for:), stopRoll(), ., for)
//#-code-completion(currentmodule, show)
//#-code-completion(identifier, hide, onCollision(data:), internalOnCollision(data:), userCode_Collision(), assessmentController)
func onCollision(data: CollisionData) {
    stopRoll()
    
}
//#-end-editable-code
//#-hidden-code
private func internalOnCollision(data: CollisionData) {
    setCollisionDetection(configuration: .disabled)
    onCollision(data: data)
    setCollisionDetection(configuration: .enabled)
    assessmentController.assessAfterCollision(data)
}

func userCode_Collision() {
    addCollisionListener(internalOnCollision)
    setCollisionDetection(configuration: .enabled)
//#-end-hidden-code
    
roll(heading: 0, speed: 100)
//#-hidden-code
}

PlaygroundPage.current.needsIndefiniteExecution = true
setupContent(assessment: assessmentController, userCode: userCode_Collision)

//#-end-hidden-code
