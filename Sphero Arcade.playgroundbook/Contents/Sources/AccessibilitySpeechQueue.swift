//
//  AccessibilitySpeechQueue.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-04-13.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public class AccessibilitySpeechQueue: NSObject, AVSpeechSynthesizerDelegate {
    typealias SpeechItem = (message: String, timestamp: TimeInterval)
    
    private var queue = [SpeechItem]()
    
    private let speaker = AVSpeechSynthesizer()
    
    private(set) var isSpeaking = false
    
    public var maxDelayTime: TimeInterval = 5.0
    
    public override init() {
        super.init()
        
        speaker.delegate = self
    }
    
    public func speak(_ message: String) {
        if !UIAccessibilityIsVoiceOverRunning() {
            return
        }
        
        // Run all operations on the main thread to avoid race conditions.
        DispatchQueue.main.async {
            self.queue.append((message: message, timestamp: Date().timeIntervalSince1970))
            self.startSpeaking()
        }
    }
    
    private func startSpeaking() {
        let now = Date().timeIntervalSince1970
        
        queue = queue.filter { item in
            return now - item.timestamp < maxDelayTime
        }
        
        if isSpeaking || queue.isEmpty { return }
        
        let item = queue.removeFirst()
        
        isSpeaking = true
        let utterance = AVSpeechUtterance(string: item.message)
        utterance.rate = 0.66
        speaker.speak(utterance)
    }
    
    private func didFinishSpeaking() {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.startSpeaking()
        }
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        didFinishSpeaking()
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        didFinishSpeaking()
    }
}
