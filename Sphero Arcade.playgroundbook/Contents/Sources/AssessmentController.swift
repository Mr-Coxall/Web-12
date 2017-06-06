//
//  AssessmentController.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-21.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import UIKit
import PlaygroundSupport

public enum AssessmentEventData {
    case roll(speed: Double, heading: Double)
    case stopRoll(heading: Double)
    
    case mainLed(color: UIColor)
    case backLed(brightness: Double)
    
    case configureLocator
    case enableSensors
    
    case startAiming
    case stopAiming
    
    case collision(data: CollisionData)
    
    case userCodeFinished
}

public struct AssessmentEvent {
    public var data: AssessmentEventData
    public var timestamp: TimeInterval
    
    public init(data: AssessmentEventData) {
        self.data = data
        self.timestamp = Date().timeIntervalSince1970
    }
}

open class AssessmentController: ToyCommandListener {
    
    private var didMakeAssessment = false
    
    public init() {}
    
    open func assess(event: AssessmentEvent) -> PlaygroundPage.AssessmentStatus? {
        fatalError("This method should be overridden")
    }
    
    public func assess(toy: ToyWrapper, userCode: @escaping () -> (), queue: DispatchQueue) {
        toy.addCommandListener(self)
        toy.addCollisionListener(self.onCollision)
        
        queue.async {
            userCode()
            self.userCodeFinished()
        }
    }
    
    public func setMainLed(color: UIColor) {
        updateAssessmentStatus(data: .mainLed(color: color))
    }
    
    public func setBackLed(brightness: Double) {
        updateAssessmentStatus(data: .backLed(brightness: brightness))
    }
    
    public func setStabilization(state: SetStabilization.State) { }
    
    public func setCollisionDetection(configuration: ConfigureCollisionDetection.Configuration) { }
    
    public func roll(heading: Double, speed: Double) {
        updateAssessmentStatus(data: .roll(speed: speed, heading: heading))
    }
    
    public func stopRoll(heading: Double) {
        updateAssessmentStatus(data: .stopRoll(heading: heading))
    }
    
    public func startAiming() {
        updateAssessmentStatus(data: .startAiming)
    }
    
    public func stopAiming() {
        updateAssessmentStatus(data: .stopAiming)
    }
    
    public func configureLocator(newX: Double, newY: Double, newYaw: Double) {
        updateAssessmentStatus(data: .configureLocator)
    }
    
    public func enableSensors(sensorMask: SensorMask) {
        updateAssessmentStatus(data: .enableSensors)
    }
    
    private func userCodeFinished() {
        updateAssessmentStatus(data: .userCodeFinished)
    }
    
    private func onCollision(_ collisionData: CollisionData) {
        updateAssessmentStatus(data: .collision(data: collisionData))
    }
    
    private func updateAssessmentStatus(data: AssessmentEventData) {
        guard !didMakeAssessment else { return }
        
        let event = AssessmentEvent(data: data)
        
        if let status = assess(event: event) {
            makeAssessment(status: status)
        }
    }
    
    public func makeAssessment(status: PlaygroundPage.AssessmentStatus) {
        guard !didMakeAssessment else { return }
        didMakeAssessment = true

        var playSoundMessageDict = [String:PlaygroundValue]()
        playSoundMessageDict[MessageKeys.type] = MessageTypeId.playAssessmentSound.playgroundValue()

        switch status {
        case .fail(hints: _, solution: _):
            playSoundMessageDict[MessageKeys.assessmentSoundKey] = .integer(0)
            
        case .pass(message: _):
            playSoundMessageDict[MessageKeys.assessmentSoundKey] = .integer(1)
            
        }
        
        PlaygroundHelpers.sendMessageToLiveView(.dictionary(playSoundMessageDict))
        
        DispatchQueue.main.async {
            PlaygroundPage.current.assessmentStatus = status
            PlaygroundPage.current.finishExecution()
        }
    }
}
