//#-hidden-code
//
//  Contents.swift
//  spheroArcade
//
//  Created by Jordan Hesse on 2017-04-26.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//
//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
 To connect, hold Sphero SPRK+ near your iPad. Make sure Bluetooth is on and Sphero is fully charged. Tap "Connect Robot" and look for your SPRK+ or BB-8 in the list. Tap on your robot to connect.
 
 Open the Glossary to learn more about the available functions. Tap ![More](threeDots.png "More") in the top right, and then select *Glossary*.

 If you’d like to start over, tap ![More](threeDots.png "More") in the top right, and then select *Reset Page*.
 */
//#-hidden-code
import Foundation
import PlaygroundSupport

//#-end-hidden-code
//#-editable-code
//#-code-completion(everything, hide)
//#-code-completion(currentmodule, show)
//#-code-completion(identifier, hide, onReady())
//#-code-completion(identifier, show, ., roll(heading:speed:), stopRoll(), wait(for:), setMainLed(color:), setBackLed(brightness:), setStabilization(state:), setCollisionDetection(configuration:), startAiming(), stopAiming(), enableSensors(sensorMask:), disableSensors(), configureLocator(newX:newY:newYaw:), addSensorListener(), addCollisionListener())
func onReady() {
    // Enable sensors for display
    enableSensors(sensorMask: [.locatorAll, .accelerometerFilteredAll, .gyroFilteredAll])

    // Roll in a square forever
    var heading = 0
    while (true) {
        // Roll
        setMainLed(color: .green)
        roll(heading: heading, speed: 100)
        wait(for: 2.0)

        // Stop
        setMainLed(color: .red)
        stopRoll()
        wait(for: 1.0)
        
        // Change heading
        heading = (heading + 90) % 360
    }
}

//#-end-editable-code
//#-hidden-code
PlaygroundPage.current.needsIndefiniteExecution = true
setupContent(assessment: TemplateAssessmentController(), userCode: onReady)
//#-end-hidden-code
