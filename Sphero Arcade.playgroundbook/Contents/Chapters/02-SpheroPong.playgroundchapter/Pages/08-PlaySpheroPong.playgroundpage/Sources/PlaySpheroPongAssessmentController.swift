//
//  PlaySpheroPongAssessmentController.swift
//  spheroArcade
//
//  Created by Jeff Payan on 2017-03-29.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import PlaygroundSupport

public final class PlaySpheroPongAssessmentController: AssessmentController {
    
    public override func assess(event: AssessmentEvent) -> PlaygroundPage.AssessmentStatus? {
        return nil
    }
    
    public func assess(declaredWinner: Int, game: SpheroPongGame) {
        makeAssessment(status: .pass(message: NSLocalizedString("playSpheroPong.success.pageComplete", value: "You've completed Sphero Pong! When you're done playing and customizing the game, head to the [next page](@next)!", comment: "[] indicator that the text will be hyper linked, @(next) is URL link that is applied to [next page], localize 'You've completed Sphero Pong! When you're done playing and customizing the game, head to the next page!'")))
    }
    
}
