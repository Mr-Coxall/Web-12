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
 **Goal:** Change Sphero's direction.
 
 Heading controls the direction Sphero rolls. It is measured as an angle from 0 to 360 degrees and is calibrated based on your aim orientation. Here are the basic directions:
 
 * 0 moves Sphero forward
 * 90 moves Sphero right
 * 180 moves Sphero backward
 * 270 moves Sphero left
 
 You set the heading angle with the `heading` parameter in the `roll` and `stopRoll` functions. Use the functions you've already learned to roll a square shape. When you run your code, the shape will be drawn on the right.
 */
//#-hidden-code
import Foundation
import PlaygroundSupport

//#-end-hidden-code
//#-editable-code
//#-code-completion(everything, hide)
//#-code-completion(identifier, show, roll(heading:speed:), wait(for:), stopRoll(), ., for)
//#-code-completion(currentmodule, show)
//#-code-completion(identifier, hide, userCode_Heading(), rollShape())
func rollShape() {

}
//#-end-editable-code
//#-hidden-code

func userCode_Heading() {
    enableSensors(sensorMask: [.locatorAll])
    rollShape()
}

PlaygroundPage.current.needsIndefiniteExecution = true
setupContent(assessment: HeadingAssessmentController(), userCode: userCode_Heading)
//#-end-hidden-code
