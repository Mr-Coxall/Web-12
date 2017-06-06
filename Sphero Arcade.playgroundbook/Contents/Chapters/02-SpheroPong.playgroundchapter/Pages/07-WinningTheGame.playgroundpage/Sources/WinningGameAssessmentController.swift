//
//  VolleyAssessmentController.swift
//  spheroArcade
//
//  Created by Jeff Payan on 2017-03-29.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import PlaygroundSupport

public final class WinningGameAssessmentController: AssessmentController {
    
    public override func assess(event: AssessmentEvent) -> PlaygroundPage.AssessmentStatus? {
        return nil
    }
    
    public func assess(declaredWinner: Int, game: SpheroPongGame) {
        if declaredWinner != 0 {
            let playerScore = game.getScore(forPlayer: declaredWinner)
            if playerScore == game.winningScore {
                // They've declared the right winner
                makeAssessment(status: .pass(message: String.localizedStringWithFormat(NSLocalizedString("winningGame.success.pageComplete", value: "### Congratulations, player %zd was the winner! \nOn to the [next page](@next).", comment: "%zd is player number, ### is bold indicator, [] indicator that the text will be hyper linked, @(next) is URL link that is applied to [next page], localize 'Congratulations, player 2 was the winner!\nOn to the next page'"), declaredWinner)))
            } else {
                // They've declared a premature winner
               makeAssessment(status: .fail(hints: [String.localizedStringWithFormat(NSLocalizedString("winningGame.fail.wrongWinner", value: "Player %zd was declared the winner, but they haven't scored %zd points yet. Fix your `checkForWinner` and try again!", comment: "winning the game assessment fail, user declared the wrong winner even though they have not yet reached the required points to win the game. first %zd is player number, i.e Player 1. second %zd is the required score, i.e. 3"), declaredWinner, game.winningScore)], solution: nil))
            }
        } else {
            // Check to make sure none of the players actually won
            for i in 1...game.numPlayers {
                let score = game.getScore(forPlayer: i)
                if score >= game.winningScore {
                    makeAssessment(status: .fail(hints: [String.localizedStringWithFormat(NSLocalizedString("winningGame.fail.noWinner", value: "Player %zd should have won, but your code didn't declare him the winner. Fix your `checkForWinner` function by returning the correct player number!", comment: "winning the game assessment fail, user didn't return the correct player number. %zd is a player number, i.e. Player 1"), i)], solution: nil))
                    return
                }
            }
        }
    }
    
}
