//
//  LiveView.swift
//  spheroArcade
//
//  Created by Jordan Hesse on 2017-04-26.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit

import PlaygroundSupport

let templateLiveViewController: TemplateLiveViewController = TemplateLiveViewController.instantiateFromStoryboard()
PlaygroundPage.current.liveView = templateLiveViewController
PlaygroundPage.current.needsIndefiniteExecution = true
