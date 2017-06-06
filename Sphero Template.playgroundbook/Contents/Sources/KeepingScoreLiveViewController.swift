//
//  VolleyLiveViewController.swift
//  spheroArcade
//
//  Created by Jeff Payan on 2017-03-31.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit

@objc(KeepingScoreLiveViewController)
public class KeepingScoreLiveViewController: SpheroPongViewController {

    @IBOutlet weak var scoreboardImageView: UIImageView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        scoreboardImageView.accessibilityLabel = NSLocalizedString("keepingScore.scoreboardImage.accessibility", value: "Sphero sitting on a scoreboard with three points for player one and one point for player two.", comment: "keeping score page image accessibility, image is Sphero sitting on a scoreboard. Scoreboard is showing player 1 winning with 3 points and player 2 with 1 point")
    }
}
