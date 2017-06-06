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
 **Goal:** Set up the playing area.
 
 Now you need to establish how big the playing area is so you know where to stand. The `distanceApart` variable is the target length of your game area.
 
 Steps to lay out the game table:
 
 1. Take about a one meter piece of maze tape from the SPRK+ box and place it on the ground. This is the line where Player 1 will stand.
 2. Choose a `distanceApart` between 150 and 250 cm, depending on how much room you have to play.
 3. Using what you learned in Chapter 1, edit the `setup` function to make Sphero roll, wait, and stop so it travels the length of the game area.
 4. Place Sphero on the ground in front of Player 1. Run your program and aim Sphero directly away from him or her.
 5. Take another meter piece of maze tape and lay it parallel to the first piece of tape, but this time where Sphero stopped. This is the line where Player 2 will stand.
 */
//#-hidden-code
import Foundation
import PlaygroundSupport
import AVFoundation

let assessmentController = RealWorldSetupAssessmentController()

//#-end-hidden-code
let distanceApart = /*#-editable-code*/150/*#-end-editable-code*/

//#-editable-code
//#-code-completion(everything, hide)
//#-code-completion(identifier, show, roll(heading:speed:), wait(for:), stopRoll(), .)
//#-code-completion(currentmodule, show)
//#-code-completion(identifier, hide, assessmentController, userCode_RealWorldSetup(), setup())
func setup() {

}
//#-end-editable-code
//#-hidden-code
func userCode_RealWorldSetup() {
    addSensorListener { data in
        let locatorY = abs(data.locator?.position?.y ?? 0.0)
        assessmentController.locatorDidUpdate(locatorY, distanceThreshold: Double(distanceApart))
    }
    enableSensors(sensorMask: [.locatorAll])

    setup()
}

PlaygroundPage.current.needsIndefiniteExecution = true
setupContent(assessment: assessmentController, userCode: userCode_RealWorldSetup)
//#-end-hidden-code
