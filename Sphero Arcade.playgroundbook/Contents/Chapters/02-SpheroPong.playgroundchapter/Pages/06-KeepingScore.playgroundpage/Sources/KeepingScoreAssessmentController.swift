//
//  VolleyAssessmentController.swift
//  spheroArcade
//
//  Created by Jeff Payan on 2017-03-29.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import PlaygroundSupport

public final class KeepingScoreAssessmentController: AssessmentController {

    private let userSensorScorer: (SensorData) -> [Int]
    
    public init(sensorScorer: @escaping (SensorData) -> [Int]) {
        self.userSensorScorer = sensorScorer
        super.init()
    }
    
    public override func assess(event: AssessmentEvent) -> PlaygroundPage.AssessmentStatus? {
        return nil
    }
    
    public func assess(data: SensorData, game: SpheroPongGame, scores: [Int]) {
        if let assessment = assessmentFor(data: data, game: game, scores: scores) {
            makeAssessment(status: assessment)
        }
    }
    
    func assessmentFor(data: SensorData, game: SpheroPongGame, scores: [Int]) -> PlaygroundPage.AssessmentStatus? {
        let threshold = game.distanceApart
        let locatorY = Int(abs(data.locator?.position?.y ?? 0.0))
        
        let currentPlayerIndex = game.currentPlayer - 1
        let otherPlayerIndex = 1 - currentPlayerIndex
        
        let currentPlayerScore = scores[currentPlayerIndex]
        let otherPlayerScore = scores[otherPlayerIndex]
        
        let wrongPlayerHint = NSLocalizedString("keepingScore.fail.wrongPlayerPoint", value: "You awarded a point to the wrong player. Try using the `currentPlayer` variable to determine who should score a point.", comment: "Keeping score assessment fail. User awarded the wrong player a point.")
    
        let noPointHint = String.localizedStringWithFormat(NSLocalizedString("keepingScore.fail.noPointScored", value: "Sphero's locator sensor reported that it travelled past %d cm and you didn't award the current player a point! Try calling `player(number:scored:)` to increase the score.", comment: "keeping score assessment fail. user didn't increase points when locator increased past the defined threshold. Locator is Sphero's sensor that reports distance travelled, %d cm is distance travelled in centimeters, ie 132 cm"), threshold)
        
        let badPointHint = String.localizedStringWithFormat(NSLocalizedString("keepingScore.fail.badPointScored", value: "You awarded a point, but Sphero's locator sensor reported that it was less than %d cm away from the center. Make sure you check that the `locatorY` variable is greater than the distance apart before giving the current player a point.", comment: "keeping score assessment fail. user increased points when locator hadn't increased past the defined threshold. Locator is Sphero's sensor that reports distance travelled, %d cm is distance travelled in centimeters, ie 132 cm"), threshold)
        
        let badAmountHint = NSLocalizedString("keepingScore.fail.wrongScoreUpdate", value: "You updated the score, but not by the right amount. Check your logic and try again.", comment: "keeping score assessment fail, user didn't correctly update the score total.")
        
        if otherPlayerScore != 0 {
            return .fail(hints:[wrongPlayerHint], solution: nil)
        }
        
        if currentPlayerScore == 0 {
            if locatorY > threshold {
                return .fail(hints:[noPointHint], solution: nil)
            }
        } else {
            if locatorY < threshold {
                return .fail(hints:[badPointHint], solution: nil)
            }
            
            if currentPlayerScore != 1 {
                return .fail(hints:[badAmountHint], solution: nil)
            }
            
            // Check that the user's code grants a point to the other player if they're the current player.
            let otherPlayer = otherPlayerIndex + 1
            game.currentPlayer = otherPlayer
            let otherPlayerScores = userSensorScorer(data)
            
            if otherPlayerScores[currentPlayerIndex] != 0 {
                return .fail(hints: [wrongPlayerHint], solution: nil)
            }
            
            if otherPlayerScores[otherPlayerIndex] == 0 {
                return .fail(hints: [noPointHint], solution: nil)
            }
            
            if otherPlayerScores[otherPlayerIndex] != 1 {
                return .fail(hints: [badAmountHint], solution: nil)
            }
            
            return .pass(message: NSLocalizedString("keepingScore.success.pageComplete", value: "### Congratulations! \nOn to the [next page](@next).", comment: "### is bold indicator, [] indicator that the text will be hyper linked, @(next) is URL link that is applied to [next page], localize 'Congratulations! \nOn to the next page'"))
        }
        
        return nil
    }
}
