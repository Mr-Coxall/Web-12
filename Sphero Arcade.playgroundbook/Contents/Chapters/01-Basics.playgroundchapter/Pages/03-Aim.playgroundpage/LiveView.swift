//
//  LiveView.swift
//  spheroArcade
//
//  Created by Jeff Payan on 2017-03-22.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import PlaygroundSupport

let aimLiveViewController: AimLiveViewController = AimLiveViewController.instantiateFromStoryboard()
PlaygroundPage.current.liveView = aimLiveViewController
PlaygroundPage.current.needsIndefiniteExecution = true
