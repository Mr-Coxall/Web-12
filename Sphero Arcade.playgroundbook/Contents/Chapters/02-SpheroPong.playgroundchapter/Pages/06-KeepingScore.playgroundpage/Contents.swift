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
 **Goal:** Award points when a player misses the ball.
 
 You'll now use Sphero's sensors to detect when a player has missed the ball. When this happens, you'll award the other player one point.
 
 Sphero sensors report its location many times a second by calling `onSensorData`. You'll add code to `onSensorData` to check Sphero's position.
 
 The "locator" sensor tells you how far Sphero has traveled. We've provided the `locatorY` variable which tells you how far Sphero has rolled towards either player.
 
 To detect when a player misses the ball, you'll check `locatorY` against the `distanceApart` variable. If the `locatorY` distance is greater, the ball has traveled too far and the current player has missed the ball. Use the `player(number:scored:)` function to award points.
 */
//#-hidden-code
import Foundation
import PlaygroundSupport

let game = KeepingScoreGame()
var testPlayerScores = [0,0]

func player(number playerNumber: Int, scored: Int) {
    if playerNumber > 0 && playerNumber <= 2 {
        testPlayerScores[playerNumber-1] += scored
    }
}

var currentPlayer: Int {
    get {
        return game.currentPlayer
    }
}

//#-end-hidden-code
let distanceApart = /*#-editable-code*/150/*#-end-editable-code*/
//#-editable-code
//#-code-completion(everything, hide)
//#-code-completion(currentmodule, show)
//#-code-completion(identifier, hide, internalOnCollision(data:), onCollision(data:), scoreSensorData(_:), onSensorData(_:), game, data, assessmentController)
//#-code-completion(identifier, show, let, var, if, else, locatorY, >, <, =, distanceApart, player(number:scored:), currentPlayer)
func onSensorData(_ data: SensorData) {
    let locatorY = Int(abs(data.locator?.position?.y ?? 0.0))

}
//#-end-editable-code

//#-hidden-code
func scoreSensorData(_ data: SensorData) -> [Int] {
    testPlayerScores = [0,0]
    onSensorData(data)
    return testPlayerScores
}

let assessmentController = KeepingScoreAssessmentController(sensorScorer: scoreSensorData)

game.distanceApart = distanceApart
game.sensorHandler = { data in
    let scores = scoreSensorData(data)
    
    for playerIndex in 0 ..< 2 {
        if scores[playerIndex] > 0 {
            game.player(number: playerIndex+1, scored: scores[playerIndex])
        }
    }
    
    assessmentController.assess(data: data, game: game, scores: scores)
}

PlaygroundPage.current.needsIndefiniteExecution = true
setupContent(assessment: assessmentController, userCode: game.play)

//#-end-hidden-code
