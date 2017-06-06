//
//  VolleyLiveViewController.swift
//  spheroArcade
//
//  Created by Jeff Payan on 2017-03-31.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit

@objc(WinningTheGameLiveViewController)
public class WinningTheGameLiveViewController: SpheroPongViewController {

    @IBOutlet weak var trophyImageView: UIImageView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        trophyImageView.accessibilityLabel = NSLocalizedString("winningGame.trophyImage.accessibility", value: "A happy Sphero sitting in a large trophy.", comment: "winning the game page image accessibility")
    }
}
