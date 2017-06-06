//
//  KeepingScoreGame.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-04-13.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation

public class KeepingScoreGame: SpheroPongGame {
    public override func restartVolley() {
        // Don't restart the volley after a player scores a point.
        disableSensors()
        setCollisionDetection(configuration: .disabled)
    }
}
