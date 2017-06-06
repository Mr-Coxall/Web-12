//
//  LiveView.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-21.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit

import PlaygroundSupport

let collisionLiveViewController: CollisionLiveViewController = CollisionLiveViewController.instantiateFromStoryboard()
PlaygroundPage.current.liveView = collisionLiveViewController
PlaygroundPage.current.needsIndefiniteExecution = true
