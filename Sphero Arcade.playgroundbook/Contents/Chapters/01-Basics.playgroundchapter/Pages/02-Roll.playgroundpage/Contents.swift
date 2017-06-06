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
 **Goal:** Get Sphero moving.
 
 You can use the `roll` function to move Sphero. Try out this program below. Experiment with different values for the parameters to the `roll` and `wait` functions.
 
 To connect, hold Sphero SPRK+ near your iPad. Make sure Bluetooth is on and Sphero is fully charged. Tap "Connect Robot" and look for your SPRK+ in the list. Tap on your robot to connect.
 
 If you’d like to start over, tap ![More](threeDots.png "More") in the top right, and then select *Reset Page*.
 */
//#-code-completion(everything, hide)
//#-hidden-code
import Foundation
import PlaygroundSupport

func userCode_Roll() {
    enableSensors(sensorMask: .locatorAll)
    
//#-end-hidden-code
roll(heading: 0, speed: /*#-editable-code*/50/*#-end-editable-code*/)
wait(for: /*#-editable-code*/3.0/*#-end-editable-code*/)
stopRoll()
//#-hidden-code
}

PlaygroundPage.current.needsIndefiniteExecution = true
setupContent(assessment: RollAssessmentController(), userCode: userCode_Roll)

//#-end-hidden-code
