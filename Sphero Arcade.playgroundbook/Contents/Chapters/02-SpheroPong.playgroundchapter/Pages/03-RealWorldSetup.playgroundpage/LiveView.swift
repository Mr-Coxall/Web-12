//
//  LiveView.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-21.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit

import PlaygroundSupport

let realWorldController: RealWorldSetupLiveViewController = RealWorldSetupLiveViewController.instantiateFromStoryboard()
PlaygroundPage.current.liveView = realWorldController
PlaygroundPage.current.needsIndefiniteExecution = true
