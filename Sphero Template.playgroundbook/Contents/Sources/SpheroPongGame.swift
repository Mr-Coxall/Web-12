//
//  SpheroPongGame.swift
//  spheroArcade
//
//  Created by Jordan Hesse on 2017-03-31.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

public class SpheroPongGame : Game {
    
    public var winningScore: Int = 3
    
    public var distanceApart = 150
    public var rollSpeed = 150
    public var bounceRandomMin = -30
    public var bounceRandomMax = 30
    
    public var collisionHandler: CollisionListener?
    public var sensorHandler: SensorListener?
    
    public var player1Color = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
    public var player2Color = #colorLiteral(red: 1, green: 0.3973274368, blue: 0.3962737091, alpha: 1)
    
    public var currentPlayer: Int = 1
    
    // The player who "serves" the ball, i.e. the volley starts with the ball moving away from this player.
    public var servingPlayer: Int = 1
    
    public var currentPlayerHeading: Int {
        get {
            return currentPlayer == servingPlayer ? 0 : 180
        }
    }
    
    public convenience init() {
        self.init(numPlayers: 2)
        
        self.checkForWinner = {
            for player in 1...2 {
                if self.getScore(forPlayer: player) == self.winningScore {
                    return player
                }
            }
            
            return 0
        }
    }
    
    public override func gameOver(winner: Int) {
        super.gameOver(winner: winner)
        
        disableSensors()
        setCollisionDetection(configuration: .disabled)
        stopRoll()
        
        if winner > 0 && winner <= numPlayers {
            PlaygroundHelpers.sendMessageToLiveView(.dictionary([
                MessageKeys.type: MessageTypeId.pongEnded.playgroundValue(),
                MessageKeys.playerNumber: .integer(winner)
                ]))
            
            // Flash the winning player's color.
            for _ in 0 ..< 20 {
                setMainLed(color: .clear)
                wait(for: 0.2)
                setMainLed(color: winner == 1 ? self.player1Color : self.player2Color)
                wait(for: 0.2)
            }
        }
    }

    public override func player(number: Int, scored points: Int) {
        super.player(number: number, scored: points)
        
        guard !isGameOver else { return }
        
        PlaygroundHelpers.sendMessageToLiveView(.dictionary([
            MessageKeys.type: MessageTypeId.pointsScored.playgroundValue(),
            MessageKeys.playerNumber: .integer(number),
            MessageKeys.points: .integer(points)
        ]))
        
        restartVolley()
    }
    
    public func restartVolley() {
        switchPlayers()
        
        reset()
        volley()
    }
    
    public override func play() {
        super.play()
        
        addCollisionListener { (collisionData: CollisionData) in
            if let collisionHandler = self.collisionHandler {
                collisionHandler(collisionData)
            } else {
                self.collisionHandlerInternal(collisionData)
            }
        }
        addSensorListener { (sensorData: SensorData) in
            if let sensorHandler = self.sensorHandler {
                sensorHandler(sensorData)
            } else {
                self.sensorHandlerInternal(sensorData)
            }
        }
        
        PlaygroundHelpers.sendMessageToLiveView(.dictionary([
            MessageKeys.type: MessageTypeId.startPong.playgroundValue(),
            MessageKeys.pongLeftPaddleColor: PlaygroundValue(color: player1Color),
            MessageKeys.pongRightPaddleColor: PlaygroundValue(color: player2Color)
            ]))
        
        enableBall(true)
        volley()
    }
    
    private func reset() {
        stopRoll()
        setMainLed(color: .black)
        
        servingPlayer = currentPlayer
        
        // Disable location & collision data *before* waiting, or else we'll get old location events after the wait.
        disableSensors()
        setCollisionDetection(configuration: .disabled)
        
        // Wait for the ball to be heading in the correct direction before aiming
        wait(for: 0.5)
        
        // Disable stabilization *after* the above wait, or the toy won't head in the right direction.
        setStabilization(state: .off)
        
        startAiming()
    
        // The live view needs 4 seconds to show the scoring animation.
        // Already waited for 0.5, wait the remaining 3.5.
        wait(for: 3.5)
        
        let timerTime = UIAccessibilityIsVoiceOverRunning() ? 10.0 : 6.0
        
        PlaygroundHelpers.sendMessageToLiveView(.dictionary([
            MessageKeys.type: MessageTypeId.showTimer.playgroundValue(),
            MessageKeys.time: PlaygroundValue.floatingPoint(timerTime)
        ]))
        
        // Wait for the timer animation to finish.
        wait(for: timerTime)
        
        stopAiming()
        enableBall(true)
    }
    
    private func enableBall(_ enabled: Bool) {
        if enabled {
            enableSensors(sensorMask: [.locatorAll])
            setCollisionDetection(configuration: .enabled)
            setStabilization(state: .on)
        } else {
            disableSensors()
            setCollisionDetection(configuration: .disabled)
            setStabilization(state: .off)
        }
    }
    
    private func volley() {
        configureLocator(newX: 0, newY: 0)
        
        if currentPlayer == 1 {
            setMainLed(color: player1Color)
        } else {
            setMainLed(color: player2Color)
        }
        
        roll(heading: currentPlayerHeading + randomAngle(), speed: rollSpeed)
    }
    
    public func randomAngle() -> Int {
        return Int(arc4random_uniform(UInt32(bounceRandomMax - bounceRandomMin))) + bounceRandomMin
    }
    
    private func collisionHandlerInternal(_ collisionData: CollisionData) {
        switchPlayers()
        volley()
    }
    
    private func sensorHandlerInternal(_ sensorData: SensorData) {
        guard let locator = sensorData.locator else { return }
        guard let locatorY = locator.position?.y else { return }
        
        if Int(abs(locatorY)) > distanceApart {
            player(number: currentPlayer, scored: 1)
        }
    }
    
    private func switchPlayers() {
        currentPlayer = currentPlayer == 1 ? 2 : 1
        
        PlaygroundHelpers.sendMessageToLiveView(.dictionary([
            MessageKeys.type: MessageTypeId.pongCurrentPlayerChanged.playgroundValue(),
            MessageKeys.playerNumber: .integer(currentPlayer)
        ]))
    }
    
}
