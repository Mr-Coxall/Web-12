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
 **Goal:** Play Sphero Pong.
 
 Now you'll play the game you just built! Here are the directions for the game:
 
 1. Find a friend and face each other while standing just behind the maze tape.
 2. Place Sphero in front of Player 1 and tap the "Run My Code" button.
 3. Player 1 should aim Sphero.
 4. Player 2 returns Sphero with your foot. You don't need to kick Sphero, just put your foot in front of it and let it collide.
 5. Continue until one player misses and a point is awarded.
 6. To reset after each point, place Sphero at your feet and aim it towards the player who scored.
 7. Play until one someone wins!
 */
//#-hidden-code
import UIKit
import PlaygroundSupport

// Stub out game interfaces so we can show something below
func player(number playerNumber: Int, scored: Int) {}
func switchPlayers() {}
func reset() {}
func randomAngle() -> Int { return 0 }
var currentPlayer = 1
var currentPlayerHeading = 0

//#-end-hidden-code
let winningScore = /*#-editable-code*/3/*#-end-editable-code*/

let distanceApart = /*#-editable-code*/150/*#-end-editable-code*/
let rollSpeed = /*#-editable-code*/100/*#-end-editable-code*/
let bounceRandomMin = /*#-editable-code*/-30/*#-end-editable-code*/
let bounceRandomMax = /*#-editable-code*/30/*#-end-editable-code*/
let player1Color = /*#-editable-code*/#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)/*#-end-editable-code*/
let player2Color = /*#-editable-code*/#colorLiteral(red: 1, green: 0.3973274368, blue: 0.3962737091, alpha: 1)/*#-end-editable-code*/

/*:#localized(key: "SecondProseBlock")
 **Sphero Pong Game Logic**
 
 See how it all fits together.
 */
func playSpheroPong() {
    // Start the game by volleying Sphero.
    volley()
}

func volley() {
    // Reset the current position of the locator to zero.
    configureLocator(newX: 0, newY: 0)

    // Change Sphero's color to indicate the current player.
    if currentPlayer == 1 {
        setMainLed(color: player1Color)
    } else {
        setMainLed(color: player2Color)
    }

    // Roll Sphero toward the other player.
    roll(heading: currentPlayerHeading + randomAngle(), speed: rollSpeed)
}

func restartVolley() {
    // Update the current player.
    switchPlayers()
    // Start the reset timer to move and aim Sphero.
    reset()
    // Once the reset is done, volley Sphero.
    volley()
}

func onCollision(_ collisionData: CollisionData) {
    // Update the current player.
    switchPlayers()
    // Volley Sphero back.
    volley()
}

func onSensorData(_ data: SensorData) {
    // Check if a player has scored.
    let locatorY = Int(abs(data.locator?.position?.y ?? 0.0))
    if locatorY > distanceApart {
        // Award the player a point.
        player(number: currentPlayer, scored: 1)
        restartVolley()
    }
}

//#-hidden-code
let assessmentController = PlaySpheroPongAssessmentController()
let game = SpheroPongGame()
game.winningScore = winningScore
game.distanceApart = distanceApart
game.rollSpeed = rollSpeed
game.bounceRandomMin = bounceRandomMin
game.bounceRandomMax = bounceRandomMax
game.player1Color = player1Color
game.player2Color = player2Color
game.onGameOver = { winner in
    assessmentController.assess(declaredWinner: winner, game: game)
}

PlaygroundPage.current.needsIndefiniteExecution = true
setupContent(assessment: assessmentController, userCode: game.play)

//#-end-hidden-code
