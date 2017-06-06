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
 **Goal:** Volley back and forth after each hit.
 
 Now you'll make Sphero travel back and forth after it collides with each player's foot. You'll need to change the base angle by 180 degrees each time. This is the core gameplay of Sphero Pong.
 
 When Sphero collides, the `onCollision` function is called. Edit this function to:
     
 1. Update the `currentPlayer` variable to the new player number (`1` or `2`).
 2. Change the LED color to indicate a player change.
 3. Call the `volley` function with the correct base angle.
 4. Include conditional logic (`if/else`) for both players.
     
 Volley Sphero back and forth a few times to check your code.
 
 */
//#-hidden-code
import Foundation
import PlaygroundSupport

let game = SpheroPongGame()
let assessmentController = VolleyAssessmentController()

func volley(baseAngle: Int) {
    wait(for: 1.0)
    let random = game.randomAngle()
    roll(heading: baseAngle + random, speed: game.rollSpeed)
}

func userCode_Volley() {
//#-end-hidden-code
var currentPlayer = 1

//#-editable-code
//#-code-completion(everything, hide)
//#-code-completion(identifier, show, if, else, currentPlayer, ==, =, volley(baseAngle:), setMainLed(color:), roll(heading:speed:), wait(for:), stopRoll())
//#-code-completion(currentmodule, show)
//#-code-completion(identifier, hide, internalOnCollision(data:), onCollision(data:), userCode_Volley(), setup(), game, assessmentController)
func onCollision(data: CollisionData) {
    stopRoll()
    
}
//#-end-editable-code
   
//#-hidden-code
func internalOnCollision(data: CollisionData) {
    setCollisionDetection(configuration: .disabled)
    onCollision(data: data)
    setCollisionDetection(configuration: .enabled)
    assessmentController.assessAfterCollision(data)
}

roll(heading: 0, speed: game.rollSpeed)
addCollisionListener(internalOnCollision)
setCollisionDetection(configuration: .enabled)
}

PlaygroundPage.current.needsIndefiniteExecution = true
setupContent(assessment: assessmentController, userCode: userCode_Volley)

//#-end-hidden-code
