//
//  LiveView.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-21.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit

import PlaygroundSupport

let sceneViewController = PongViewController()
sceneViewController.shouldAutomaticallyConnectToToy = false
sceneViewController.view.backgroundColor = .black

PlaygroundPage.current.liveView = sceneViewController
PlaygroundPage.current.needsIndefiniteExecution = true
