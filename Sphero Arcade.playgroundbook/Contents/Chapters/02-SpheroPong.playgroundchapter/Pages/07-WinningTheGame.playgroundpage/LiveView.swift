//
//  LiveView.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-21.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit

import PlaygroundSupport

let winningGameController: WinningTheGameLiveViewController = WinningTheGameLiveViewController.instantiateFromStoryboard()
PlaygroundPage.current.liveView = winningGameController
PlaygroundPage.current.needsIndefiniteExecution = true
