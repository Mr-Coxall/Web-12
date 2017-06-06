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
 **Goal:** Aim Sphero so it goes the direction you want.
 
 You probably noticed that Sphero didn't roll in the direction you expected. You can fix that by aiming Sphero.
 
 Whenever you run your code, a pop-up will appear giving you the chance to aim Sphero. You'll know Sphero is ready to aim when the main LED turns off and the blue tail light turns on. To aim Sphero, place it on the floor and turn it until the blue tail light faces you.
 
 Practice aiming until you can predict exactly which direction Sphero will roll. Using the functions from the previous page, edit `rollBack` to make Sphero return to you after it rolls away.
 
 */
//#-hidden-code
import Foundation
import PlaygroundSupport

//#-end-hidden-code
func rollAway() {
    roll(heading: 0, speed: 50)
    wait(for: 3.0)
    stopRoll()
}

//#-editable-code
//#-code-completion(everything, hide)
//#-code-completion(currentmodule, show)
//#-code-completion(identifier, hide, userCode_Aim(), rollAway(), rollBack())
//#-code-completion(identifier, show, ., roll(heading:speed:), stopRoll(), wait(for:))
func rollBack() {

}
//#-end-editable-code
//#-hidden-code
func userCode_Aim() {
//#-end-hidden-code
    
rollAway()
wait(for: 2.0)
rollBack()
//#-hidden-code
}

PlaygroundPage.current.needsIndefiniteExecution = true
setupContent(assessment: AimAssessmentController(), userCode: userCode_Aim)

//#-end-hidden-code
