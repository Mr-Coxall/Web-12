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
 **Goal:** End the game when one player scores 3 points.
 
 Sphero calls `checkForWinner` every time a point is scored. The current scores for Player 1 and Player 2 are passed as arguments for you to use.
 
 Add code in `checkForWinner` to check the players' scores and decide if either one has won the game. Return the player number (`1` or `2`) if a player wins. If no one has won, return `0`.
 */
//#-hidden-code
import Foundation
import PlaygroundSupport

let assessmentController = WinningGameAssessmentController()
let game = SpheroPongGame()

//#-end-hidden-code
let winningScore = 3
let distanceApart = /*#-editable-code*/150/*#-end-editable-code*/
//#-hidden-code

//#-end-hidden-code
//#-editable-code
//#-code-completion(everything, hide)
//#-code-completion(identifier, show, player1Score, player2Score, if, else, var, ==, return, winningScore)
//#-code-completion(currentmodule, show)
//#-code-completion(identifier, hide, checkForWinner(player1Score:player2Score:), game, assessmentController)

func checkForWinner(player1Score: Int, player2Score: Int) -> Int {

    return 0
}
//#-end-editable-code
//#-hidden-code
game.checkForWinner = {
    let winner = checkForWinner(player1Score: game.getScore(forPlayer: 1), player2Score: game.getScore(forPlayer: 2))
    assessmentController.assess(declaredWinner: winner, game: game)
    
    let actualWinner = (1...2).first { game.getScore(forPlayer: $0) >= winningScore } ?? 0
    
    // Stop the game without a winner when a mistake is made.
    if winner != actualWinner {
        game.gameOver(winner: 0)
        return 0
    }

    return winner
}

game.winningScore = winningScore
game.distanceApart = distanceApart

PlaygroundPage.current.needsIndefiniteExecution = true
setupContent(assessment: assessmentController, userCode: game.play)
//#-end-hidden-code
