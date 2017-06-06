//
//  PongScene.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-28.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import SpriteKit
import UIKit
import PlaygroundSupport

private let ballCategory: UInt32 = 1 << 0
private let paddleCategory: UInt32 = 1 << 1
private let wallCategory: UInt32 = 1 << 2
private let goalCategory: UInt32 = 1 << 3

private let paddleSize = CGSize(width: 18.0, height: 109)
private let ballSize = CGSize(width: 36.0, height: 36.0)

private let paddleX: CGFloat = 210.0

// This is the size of the safe area of the right-side of the playgrounds app in landscape.
private let sceneSize = CGSize(width: 512.0, height: 684.0)

private let wallWidth: CGFloat = 100.0
private let goalWidth: CGFloat = 100.0

private let messageLabelHeight: CGFloat = 67.0

private let topBarHeight: CGFloat = 91.0

private let playFieldSize = CGSize(width: sceneSize.width, height: sceneSize.height - topBarHeight)

private let maxPaddleVelocity: CGFloat = 500.0

private let instructionsFontSize: CGFloat = 23.0
private let scoreFontSize: CGFloat = 68.0
private let winnerFontSize: CGFloat = 71.0

private let defaultBackgroundColor = #colorLiteral(red: 0.524340868, green: 0.6308438182, blue: 0.677141428, alpha: 1)
private let defaultPaddleColor = #colorLiteral(red: 0.2916591763, green: 0.4149196744, blue: 0.4695840478, alpha: 1)
private let topBarColor = UIColor(white: 1.0, alpha: 0.31)

private let playAgainMessage = NSLocalizedString("OriginalPong_PlayAgainButton", value: "PLAY AGAIN", comment: "Button to play another game of pong after a game is played.")

public class PongScene: SKScene, SKPhysicsContactDelegate {
    
    private var ballNode: SKSpriteNode
    
    private var ballSpeed: CGFloat = 200.0
    
    private var currentPlayerIndex = 1
    private var playerScores = [0,0]
    
    private var paddleNodes: [PaddleNode] = []
    
    private let playerCount = 2
    
    private var wallNodes: [SKNode] = []
    private var goalNodes: [SKNode] = []
    
    private var messageNode: PongLabelNode
    
    private var scoreContainerNodes: [SKNode] = []
    
    private var isRunning = false
    
    public var initialBallSpeed: CGFloat = 200.0
    public var ballSpeedIncrement: CGFloat = 20.0
    public var maxBallSpeed: CGFloat = 900.0
    
    private var gameNode: SKNode
    private var resultsNode: SKNode
    private var topBarNode: SKShapeNode
    
    private var winnerMessageContainerNode: SKNode
    private var resetNode: SKNode
    private var resetIconNode: SKNode
    
    public weak var viewController: PongViewController?
    
    private let fireNode: SKEmitterNode?
    private var isBoostEnabled = false
    
    private var nonBoostBackgroundColor = defaultBackgroundColor
    
    public let speaker = AccessibilitySpeechQueue()
    
    private let thunderSound = Sound("lightning", volume: 0.1)
    private let paddleSound = Sound("paddle", volume: 0.1)
    private let wallSound = Sound("wall", volume: 0.1)
    private let scoreSound = Sound("score", volume: 0.1)
    private let winSound = Sound("win", volume: 0.1)
    
    private let accessibilitySoundGenerator = PongAccessibilitySoundGenerator()
    
    private let runCodeToPlayMessage = NSLocalizedString("OriginalPong_PlayButton", value: "RUN CODE TO PLAY", comment: "Message prompting the user to run their code in order to play a game of pong.")
    
    private var isSoundModeEnabled = false
    
    public override init(size: CGSize) {
        let screenBounds = UIScreen.main.bounds
        let maxScreenSize = max(screenBounds.width, screenBounds.height)
        
        topBarNode = SKShapeNode(rectOf: CGSize(width: maxScreenSize, height: topBarHeight))
        topBarNode.fillColor = topBarColor
        topBarNode.strokeColor = .clear
        
        ballNode = SKSpriteNode(imageNamed: "sphero8Bit")
        ballNode.zPosition = 2
        ballNode.isAccessibilityElement = true
        ballNode.accessibilityTraits = UIAccessibilityTraitImage
        ballNode.accessibilityHint = NSLocalizedString("OriginalPong_AccessibilitySpheroHint", value: "8-bit Sphero", comment: "Accessibility hint for 8-bit Sphero image in original pong.")
        
        fireNode = SKEmitterNode(fileNamed: "Fire")
        
        let ballBody = SKPhysicsBody(rectangleOf: ballSize)
        ballNode.physicsBody = ballBody
        ballBody.affectedByGravity = false
        ballBody.linearDamping = 0.0
        ballBody.categoryBitMask = ballCategory
        ballBody.collisionBitMask = 0
        ballBody.contactTestBitMask = paddleCategory | wallCategory | goalCategory
        ballBody.allowsRotation = false
        
        for i in 0 ..< playerCount {
            let paddleNode = PaddleNode()
            paddleNode.position.x = i == 0 ? -paddleX : paddleX
            paddleNode.zPosition = 1
            paddleNodes.append(paddleNode)
            
            let goalSize = CGSize(width: goalWidth, height:maxScreenSize)
            let goalNode = SKNode()
            let goalBody = SKPhysicsBody(rectangleOf: goalSize)
            goalNode.physicsBody = goalBody
            let goalOffset = sceneSize.width / 2.0 + goalWidth / 2.0 + 1.0
            goalNode.position.x = i == 0 ? -goalOffset : goalOffset
            goalNode.position.y = 0.0
            goalBody.isDynamic = false
            goalBody.categoryBitMask = goalCategory
            
            goalNodes.append(goalNode)
            
            let scoreNode = SKNode()
            
            scoreNode.zPosition = 1
            scoreContainerNodes.append(scoreNode)
        }
        
        for i in 0 ..< 2 {
            let wallSize = CGSize(width: maxScreenSize, height: wallWidth)
            let wallNode = SKNode()
            let wallBody = SKPhysicsBody(rectangleOf: wallSize)
            wallNode.physicsBody = wallBody
            let wallOffset = sceneSize.height / 2.0 + wallWidth / 2.0 + 1.0
            wallNode.position.x = 0.0
            wallNode.position.y = i == 0 ? -wallOffset : wallOffset
            wallBody.affectedByGravity = false
            wallBody.categoryBitMask = wallCategory
            wallBody.collisionBitMask = 0
            wallBody.contactTestBitMask = 0
            
            wallNodes.append(wallNode)
        }
        
        messageNode = PongLabelNode(text: runCodeToPlayMessage, fontSize: instructionsFontSize)
        
        // Split everything into game & results nodes so we can easily show one or the other.
        gameNode = SKNode()
        resultsNode = SKNode()
        
        resetNode = PongLabelNode(text: playAgainMessage, fontSize: 27.0)
        resetNode.position.y = -102.0
        resetNode.position.x = 25.0
        resetNode.accessibilityTraits = UIAccessibilityTraitButton
        
        resetIconNode = SKSpriteNode(imageNamed: "spheroPlayAgain")
        resetIconNode.position.y = -93.0
        resetIconNode.position.x = resetNode.frame.minX - 35.0
        
        winnerMessageContainerNode = SKNode()
        winnerMessageContainerNode.position.y = 36.0
        
        super.init(size: size)
        
        if let fireNode = fireNode {
            fireNode.zPosition = 1
            fireNode.targetNode = self
        }
        
        gameNode.addChild(ballNode)
        
        paddleNodes.forEach(gameNode.addChild)
        goalNodes.forEach(gameNode.addChild)
        wallNodes.forEach(gameNode.addChild)
        
        resultsNode.addChild(winnerMessageContainerNode)
        resultsNode.addChild(resetNode)
        resultsNode.addChild(resetIconNode)
        
        // This puts the origin in the middle of the screen.
        let cameraNode = SKCameraNode()
        self.addChild(cameraNode)
        cameraNode.position = .zero
        self.camera = cameraNode
        
        scoreContainerNodes.forEach(cameraNode.addChild)
        
        self.scaleMode = .resizeFill
        
        self.physicsWorld.contactDelegate = self
        
        self.isUserInteractionEnabled = true
        self.view?.isUserInteractionEnabled = true
        
        self.scaleMode = .resizeFill
        
        let netPath = UIBezierPath()
        netPath.move(to: CGPoint(x: 0, y: playFieldSize.height / 2.0))
        netPath.addLine(to: CGPoint(x: 0, y: -playFieldSize.height / 2.0))
        
        let dashedLine = netPath.cgPath.copy(dashingWithPhase: 2, lengths: [20.0, 10.0])
        let netNode = SKShapeNode(path: dashedLine)
        netNode.strokeColor = .white
        netNode.fillColor = .clear
        netNode.lineWidth = 3.0
        gameNode.addChild(netNode)
        
        topBarNode.addChild(messageNode)
        
        self.backgroundColor = nonBoostBackgroundColor
        
        cameraNode.addChild(topBarNode)
        
        reset()
    }
    
    public override convenience init() {
        self.init(size: sceneSize)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func reset() {
        currentPlayerIndex = Int(arc4random_uniform(2))
        
        playerScores = [0,0]
        for i in 0 ..< playerCount {
            scoreContainerNodes[i].removeAllChildren()
            scoreContainerNodes[i].addChild(PongLabelNode(text:"0", fontSize: scoreFontSize))
        }
        
        if gameNode.parent == nil {
            addChild(gameNode)
        }
        
        if resultsNode.parent != nil {
            resultsNode.removeFromParent()
        }
        
        setMessageText(runCodeToPlayMessage)
        
        resetBall()
        
        viewController?.reset()
    }
    
    private func resetBall() {
        ballNode.position = .zero
        ballSpeed = initialBallSpeed
        
        isBoostEnabled = false
        
        if fireNode?.parent != nil {
            fireNode?.removeFromParent()
        }
        
        ballNode.physicsBody?.velocity = velocityForCurrentPlayer()
        
        self.removeAllActions()
        self.run(.colorize(with: nonBoostBackgroundColor, colorBlendFactor: 1.0, duration: 0.5))
        
        updatePaddleVelocities()
    }
    
    public func didBegin(_ contact: SKPhysicsContact) {
        guard let ballBody = ballNode.physicsBody else { return }
        
        for body in [contact.bodyA, contact.bodyB] {
            if body.categoryBitMask & paddleCategory != 0 {
                if body === paddleNodes[currentPlayerIndex].physicsBody {
                    let paddleNode = paddleNodes[currentPlayerIndex]
                    
                    // If the ball is moving horizontally towards the paddle
                    // (If the sign of the horizontal velocity is the same as the sign of the difference in horizontal position)
                    let differenceInHorizontalPositionDirection = (paddleNode.position.x - ballNode.position.x > 0.0)
                    let horizontalVelocityDirection = ballBody.velocity.dx > 0.0
                    
                    if horizontalVelocityDirection == differenceInHorizontalPositionDirection {
                        currentPlayerIndex = 1 - currentPlayerIndex
                        
                        let combinedBallSpeed = ballSpeed + ballSpeedIncrement
                        ballSpeed = min(combinedBallSpeed, maxBallSpeed)
                        
                        // Only enable boost mode if the paddle is controlled by a real player.
                        if !isBoostEnabled && ballSpeed == maxBallSpeed && ballSpeed >= 800.0 && paddleNode.currentTouch != nil {
                            isBoostEnabled = true
                            
                            if let fireNode = fireNode,
                                fireNode.parent == nil {
                                
                                ballNode.addChild(fireNode)
                            }
                            
                            for _ in 0 ..< 4 {
                                makeLightning()
                            }
                            thunderSound.play()
                            
                            speaker.speak(NSLocalizedString("OriginalPong_LightningVoiceOverMessage", value: "Lightning strikes Sphero. Sphero is on fire.", comment: "VoiceOver message when lightning strikes Sphero in original pong."))
                        }
                        
                        ballBody.velocity = velocityForCurrentPlayer()
                        
                        updatePaddleVelocities()
                        paddleSound.play()
                    }
                }
            }
        }
    }
    
    public func makeLightning() {
        
        let angle = CGFloat(arc4random_uniform(360)) * .pi / 180.0
        
        let startPoint = CGPoint(x: cos(angle) * 512.0, y: sin(angle) * 512.0)
        let endPoint = CGPoint(
            x: gameNode.position.x + ballNode.position.x,
            y: gameNode.position.y + ballNode.position.y
        )
        
        let lightningPath = UIBezierPath()
        lightningPath.move(to: startPoint)
        lightningPath.bolt(to: endPoint)
        lightningPath.lineCapStyle = .round
        
        let lightningNode = SKShapeNode(path: lightningPath.cgPath)
        lightningNode.strokeColor = #colorLiteral(red: 0.94603125, green: 0.913292536, blue: 0.7625273027, alpha: 1)
        lightningNode.fillColor = .clear
        lightningNode.glowWidth = 5.0
        lightningNode.lineWidth = 2.0
        lightningNode.blendMode = .add
        lightningNode.zPosition = 50
        
        let boomNode = SKShapeNode(circleOfRadius: 2.0)
        boomNode.strokeColor = #colorLiteral(red: 0.9574479167, green: 0.9265239924, blue: 0.8587678394, alpha: 1)
        boomNode.fillColor = boomNode.strokeColor
        boomNode.glowWidth = 10.0
        boomNode.blendMode = .add
        boomNode.position = endPoint
        lightningNode.addChild(boomNode)
        
        
        addChild(lightningNode)
        
        let fade = SKAction.fadeAlpha(to: 0.0, duration: 0.3)
        let remove = SKAction.run {
            lightningNode.removeFromParent()
        }
        
        lightningNode.run(SKAction.sequence([fade, remove]))
        
        self.backgroundColor = #colorLiteral(red: 0.32303125, green: 0.312426645, blue: 0.2608727871, alpha: 1)
        self.run(SKAction.colorize(with: .black, colorBlendFactor: 1.0, duration: 0.3))
    }
    
    private func velocityForCurrentPlayer() -> CGVector {
        let speed = UIAccessibilityIsVoiceOverRunning() ? 0.5 * ballSpeed : ballSpeed
        return CGVector(
            dx: currentPlayerIndex == 0 ? -speed : speed,
            dy: randomYVelocity()
        )
    }
    
    private func randomYVelocity() -> CGFloat {
        let speed = UIAccessibilityIsVoiceOverRunning() ? 0.5 * ballSpeed : ballSpeed
        let absBallSpeed: CGFloat = abs(speed) * 2.0
        let uIntBallSpeed: UInt32 = UInt32(absBallSpeed)
        
        return CGFloat(arc4random_uniform(uIntBallSpeed)) - speed
    }
    
    private func updatePaddleVelocities() {
        
        let currentPaddleNode = paddleNodes[currentPlayerIndex]
        let otherPaddleNode = paddleNodes[1 - currentPlayerIndex]
        
        currentPaddleNode.aiMoveTowards(ball: ballNode)
        otherPaddleNode.aiStop()
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // TODO : Better way to check this
        if gameNode.parent == self {
            for touch in touches {
            
                if UIAccessibilityIsVoiceOverRunning() {
                    paddleNodes[0].currentTouch = touch
                    paddleNodes[0].moveToTouch()
                } else {
                    for paddle in paddleNodes {
                        if paddle.currentTouch == nil {
                            let loc = touch.location(in: paddle)
                            if hypot(loc.x, loc.y) < paddleSize.height {
                                paddle.currentTouch = touch
                                paddle.moveToTouch()
                            }
                        }
                    }
                }
            }
        }
        else {
            for touch in touches {
                let touchLocation = touch.location(in: resultsNode)
                
                // Check if the touch is within the bounding rectangle of the reset label and reset icon.
                // SWFT-123 - Give 20px extra
                let resetFrameLeft = resetIconNode.frame.minX - 20.0
                let resetFrameRight = resetNode.frame.maxX + 20.0
                let resetFrameBottom = resetNode.frame.minY - 20.0
                let resetFrameTop = resetNode.frame.maxY + 20.0
                
                let resetFrame = CGRect(x: resetFrameLeft, y: resetFrameBottom, width: resetFrameRight - resetFrameLeft, height: resetFrameTop - resetFrameBottom)
                
                if resetFrame.contains(touchLocation) {
                    self.playAgain()
                }
            }
        }
    }
    
    public func playAgain() {
        startPlaying()
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        paddleNodes.forEach { $0.moveToTouch() }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for paddle in paddleNodes {
            if let touch = paddle.currentTouch {
                if touches.contains(touch) {
                    paddle.currentTouch = nil
                    paddle.touchOffset = 0.0
                    updatePaddleVelocities()
                }
            }
        }
    }
    
    public override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        view.isPaused = !isRunning
    }
    
    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        
        let safeFrame = viewController?.liveViewSafeAreaFrame ?? CGRect(origin: .zero, size: size)
        // Convert to SpriteKite coordinates.
        let skSafeFrame = CGRect(
            x: safeFrame.minX - size.width/2.0,
            y: size.height/2.0 - safeFrame.maxY,
            width: safeFrame.width,
            height: safeFrame.height
        )
        
        let isLandscape = skSafeFrame.size.width > skSafeFrame.size.height
        
        let topBarY = skSafeFrame.maxY - topBarHeight / 2.0
        
        topBarNode.position.y = topBarY
        topBarNode.fillColor = isLandscape ? .clear : topBarColor
        
        let scoreNodeOffsetX = skSafeFrame.size.width / 2.0 - 50.0
        for (index,scoreNode) in scoreContainerNodes.enumerated() {
            let direction: CGFloat = index == 0 ? -1 : 1
            scoreNode.position.x = skSafeFrame.midX + direction * scoreNodeOffsetX
            scoreNode.position.y = skSafeFrame.maxY - 65.0
        }
        
        messageNode.position.y = isLandscape ? 10.0 : -5.0
        messageNode.position.x = skSafeFrame.midX
        
        updateMessageScale()
        
        let usedHeight: CGFloat = isLandscape ? 50.0 : topBarHeight
        let remainingHeight = skSafeFrame.size.height - usedHeight
        
        let minCameraScaleX = playFieldSize.width / skSafeFrame.size.width
        let minCameraScaleY = playFieldSize.height / remainingHeight
        
        let cameraScale = max(minCameraScaleX, minCameraScaleY)
        
        camera?.xScale = cameraScale
        camera?.yScale = cameraScale
        
        gameNode.position.x = skSafeFrame.midX * cameraScale
        gameNode.position.y = (skSafeFrame.minY + remainingHeight / 2.0) * cameraScale
    }
    
    private func updateMessageScale() {
        let scorePositions = self.scoreContainerNodes.map({ $0.position.x })
        
        let maxX = scorePositions.max() ?? 0.0
        let minX = scorePositions.min() ?? 0.0
        let availableWidth = maxX - minX - 50.0
        
        messageNode.maxWidth = availableWidth
    }
    
    private func setMessageText(_ text: String) {
        messageNode.text = text
        updateMessageScale()
        viewController?.setMessageText(text)
    }
    
    public override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        guard let ballBody = ballNode.physicsBody else { return }
        
        // SpriteKit's contact/collision detection seems to fail sometimes.
        // Ensure everything stays in the scene.
        let maxPaddleY = (playFieldSize.height - paddleSize.height) / 2.0
        let minPaddleY = (-playFieldSize.height + paddleSize.height) / 2.0
        for paddle in paddleNodes {
            var didChangePosition = false
            
            if paddle.position.y > maxPaddleY {
                paddle.position.y = maxPaddleY
                didChangePosition = true
            }
            if paddle.position.y < minPaddleY {
                paddle.position.y = minPaddleY
                didChangePosition = true
            }
            
            if didChangePosition && UIAccessibilityIsVoiceOverRunning() {
                if let touch = paddle.currentTouch {
                    paddle.touchOffset = -touch.location(in: paddle).y
                }
            }
        }
        
        let maxBallY = (playFieldSize.height - ballSize.height) / 2.0
        let minBallY = (-playFieldSize.height + ballSize.height) / 2.0
        
        var didBallHitWall = false
        
        if ballNode.position.y > maxBallY {
            didBallHitWall = true
            ballNode.position.y = maxBallY
        }
        
        if ballNode.position.y < minBallY {
            didBallHitWall = true
            ballNode.position.y = minBallY
        }
        
        if didBallHitWall {
            // If the ball is moving away from the origin, bounce it towards the origin
            if (ballBody.velocity.dy > 0) == (ballNode.position.y > 0) {
                ballBody.velocity.dy = -ballBody.velocity.dy
                updatePaddleVelocities()
                wallSound.play()
            }
        }
        
        let maxBallXOffset = (sceneSize.width - ballSize.width) / 2.0
        if abs(ballNode.position.x) as CGFloat > maxBallXOffset {
            let scoringPlayerIndex = ballNode.position.x > 0 ? 0 : 1
            currentPlayerIndex = scoringPlayerIndex
            playerScores[scoringPlayerIndex] += 1
            viewController?.setScore(playerScores[scoringPlayerIndex], forPlayer: scoringPlayerIndex)

            let paddleNumber = scoringPlayerIndex == 0 ? 2 : 1
            let playerNumber = scoringPlayerIndex + 1
            
            let message = String(
                format: NSLocalizedString("OriginalPong_AccessibilityScorePointMessage",
                                          value: "The Sphero went past player %d\'s paddle, scoring a point for player %d.",
                                          comment: "VoiceOver message when a player scores a point in original pong"),
                paddleNumber, playerNumber
            )
            
            speaker.speak(message)
            
            if playerScores[scoringPlayerIndex] < 10 {
                let scoreText = "\(playerScores[scoringPlayerIndex])"
                scoreContainerNodes[scoringPlayerIndex].removeAllChildren()
                scoreContainerNodes[scoringPlayerIndex].addChild(PongLabelNode(text: scoreText, fontSize: scoreFontSize))
            }
            
            if playerScores[scoringPlayerIndex] == 3 {
                let winner = scoringPlayerIndex + 1
                
                winnerMessageContainerNode.removeAllChildren()
                
                let winningMessageFormat = NSLocalizedString("OriginalPong_WinningMessage", value: "PLAYER\n%d WINS!", comment: "Message when a player wins a game of pong. \"%d\" is replaced with the winning player, 1 or 2.")
                
                let winningMessage = String(format: winningMessageFormat, winner)
                
                speaker.speak(winningMessage)
                
                let lines = winningMessage.components(separatedBy: "\n")
                
                let topLine = lines.count >= 1 ? lines[0] : ""
                let bottomLine = lines.count >= 2 ? lines[1] : ""
                
                let line1 = PongLabelNode(text:topLine, fontSize: winnerFontSize)
                winnerMessageContainerNode.addChild(line1)
                line1.isAccessibilityElement = false
                line1.maxWidth = self.size.width - 40.0
                
                let line2 = PongLabelNode(text:bottomLine, fontSize: winnerFontSize)
                line2.position = CGPoint(x: line1.position.x, y: line1.position.y - winnerFontSize)
                winnerMessageContainerNode.addChild(line2)
                line2.isAccessibilityElement = false
                line2.maxWidth = self.size.width - 40.0
                
                let isVeryCompact = self.size.height < 420.0
                
                if isVeryCompact {
                    for scoreContainer in scoreContainerNodes {
                        scoreContainer.removeAllChildren()
                    }
                }
                
                self.gameNode.removeFromParent()
                self.camera?.addChild(resultsNode)
                self.setMessageText("")
                
                viewController?.gameFinished(message: winningMessage)
                
                ballNode.position = .zero
                ballNode.physicsBody?.velocity = .zero
                winSound.play()
            } else {
                resetBall()
                scoreSound.play()
            }
        }
        
        if isBoostEnabled && arc4random_uniform(45) == 0 {
            makeLightning()
            thunderSound.play()
        }
        
        let isBallMovingAway = (ballNode.position.x > paddleNodes[0].position.x) == (ballBody.velocity.dx > 0)
        
        if isBallMovingAway || gameNode.parent == nil {
            // ball is moving away from the paddle - no sound.
            accessibilitySoundGenerator.volume = 0.0
        }
        else {
            let distanceX = abs(paddleNodes[0].position.x - ballNode.position.x) as CGFloat - (ballSize.width + paddleSize.width) / 2.0
            let time = distanceX / abs(ballBody.velocity.dx) as CGFloat
            
            var predictedY = ballNode.position.y + time * ballBody.velocity.dy
            while predictedY > maxBallY {
                predictedY = 2.0 * maxBallY - predictedY
            }
            while predictedY < minBallY {
                predictedY = 2.0 * minBallY - predictedY
            }
            
            let distanceY = abs(predictedY - paddleNodes[0].position.y) as CGFloat / (maxBallY - minBallY)
            
            let volume = distanceY / 2.0
            
            accessibilitySoundGenerator.volume = min(0.15, Float(volume))
            
            let frequency: Float32 = predictedY > paddleNodes[0].position.y ? 500 : 250
            accessibilitySoundGenerator.waveFrequency = frequency
            accessibilitySoundGenerator.pulseFrequency = 6.0 + Float32(distanceY) * 6.0
        }
    }
    
    public func startPlaying() {
        isRunning = true
        self.view?.isPaused = false
        
        reset()
        
        setMessageText(NSLocalizedString("OriginalPong_TouchPaddle", value: "TOUCH PADDLE TO PLAY", comment: "Message prompting user to touch a paddle in original pong to control it."))
        
        if isSoundModeEnabled && !accessibilitySoundGenerator.isPlaying {
            accessibilitySoundGenerator.start()
        }
    }
    
    public func stopPlaying() {
        reset()
        
        isRunning = false
        self.view?.isPaused = true
        
        setMessageText(runCodeToPlayMessage)
        
        if accessibilitySoundGenerator.isPlaying {
            accessibilitySoundGenerator.stop()
        }
    }
    
    public func setPaddle(color: UIColor, forPlayer playerIndex:Int) {
        paddleNodes[playerIndex].setColor(color)
    }
    
    public func setBall(color: UIColor) {
        ballNode.color = color
        ballNode.colorBlendFactor = 1.0
    }
    
    public func setBackground(color: UIColor) {
        nonBoostBackgroundColor = color
        if !isBoostEnabled {
            self.backgroundColor = color
        }
    }
    
    public func setSoundModeEnabled(_ enabled: Bool) {
        isSoundModeEnabled = enabled
        
        if enabled {
            speaker.speak(NSLocalizedString("SpheroPong_SoundModeOnAccessibilityMessage", value: "Sound mode on.", comment: "VoiceOver message when sound mode is turned on in original pong. Sound mode is an accessibility feature which plays sounds to tell the user where the ball is relative to the paddle."))
        
            if !self.accessibilitySoundGenerator.isPlaying {
                speaker.speak(NSLocalizedString("SpheroPong_SoundModeAccessibilityExplanation", value: "A pulse is played while Sphero is rolling towards your paddle. A high pitch means Sphero is above your paddle. A low pitch means Sphero is below your paddle. The louder and faster the pulse, the further away Sphero is from your paddle.", comment: "VoiceOver description of sound mode in original pong. Sound mode is an accessibility feature which plays sounds to tell the user where the ball is relative to the paddle."))
                self.accessibilitySoundGenerator.start()
            }
        } else {
            speaker.speak(NSLocalizedString("SpheroPong_SoundModeOffAccessibilityMessage", value: "Sound mode off.", comment: "VoiceOver message when sound mode is turned off in original pong. Sound mode is an accessibility feature which plays sounds to tell the user where the ball is relative to the paddle."))
        
            if self.accessibilitySoundGenerator.isPlaying {
                self.accessibilitySoundGenerator.stop()
            }
        }
    }
    
    public func muteSoundMode() {
        if accessibilitySoundGenerator.isPlaying {
            accessibilitySoundGenerator.stop()
        }
    }
    
    public func unmuteSoundMode() {
        if isSoundModeEnabled && !accessibilitySoundGenerator.isPlaying {
            accessibilitySoundGenerator.start()
        }
    }
}

public class PongLabelNode: AutoshrinkLabelNode {
    public convenience init(text: String, fontSize: CGFloat) {
        self.init(fontNamed: UIFont.arcadeFontName)
        
        self.text = text
        self.fontColor = .white
        self.fontSize = fontSize
    }
}

public class PaddleNode: SKNode {
    public var currentTouch: UITouch?
    
    private var shapeNode: SKShapeNode
    private var cropNode: SKCropNode
    
    public var touchOffset: CGFloat = 0.0
    
    public override init() {
        
        self.shapeNode = SKShapeNode(rectOf: paddleSize)
        self.cropNode = SKCropNode()
        
        super.init()
        
        shapeNode.fillColor = defaultPaddleColor
        shapeNode.strokeColor = defaultPaddleColor
        
        cropNode.maskNode = SKSpriteNode(imageNamed: "paddle8Bit")
        cropNode.addChild(shapeNode)
        
        self.addChild(cropNode)
        
        // Add extra width to the paddle
        // Without this, it looks like the ball goes a little bit through the paddle
        let body = SKPhysicsBody(rectangleOf: CGSize(width: paddleSize.width + 10, height: paddleSize.height))
        self.physicsBody = body
        body.affectedByGravity = false
        body.linearDamping = 0.0
        body.categoryBitMask = paddleCategory
        body.collisionBitMask = wallCategory
        body.contactTestBitMask = 0
        body.allowsRotation = false
        
        shapeNode.isAccessibilityElement = true
        shapeNode.accessibilityHint = NSLocalizedString("OriginalPong_AccessibilityHintPaddle", value: "Paddle", comment: "VoiceOver accessibility hint for pong paddle.")
        shapeNode.accessibilityTraits = UIAccessibilityTraitImage
    }
    
    public func moveToTouch() {
        if let touch = currentTouch {
            self.physicsBody?.velocity = .zero
            self.position.y += touch.location(in: self).y + touchOffset
        }
    }
    
    public func aiMoveTowards(ball ballNode: SKNode) {
        // Disable AI if the paddle is being touch-controlled.
        if currentTouch != nil { return }
        
        guard let ballBody = ballNode.physicsBody else { return }
        
        let xDiff = self.position.x - ballNode.position.x
        let time = xDiff / ballBody.velocity.dx
        let yDestination = ballNode.position.y + time * ballBody.velocity.dy
        
        let yDiff = yDestination - self.position.y
        var yPaddleVelocity = yDiff / time
        
        // Add up to 20% error, more for accessibility mode
        // This makes it so that slower speeds are more likely to succeed.
        // Extra error in accessibility mode
        let maxError = UIAccessibilityIsVoiceOverRunning() ? 0.3 : 0.2
        
        let error = (Double.random() * 2.0 - 1.0) * maxError
        yPaddleVelocity *= CGFloat(1.0 + error)
        
        if abs(yPaddleVelocity) > maxPaddleVelocity {
            yPaddleVelocity = copysign(maxPaddleVelocity, yPaddleVelocity)
        }
        
        self.physicsBody?.velocity = CGVector(dx: 0.0, dy: yPaddleVelocity)
    }
    
    public func aiStop() {
        // Disable AI if the paddle is being touch-controlled.
        if currentTouch != nil { return }
        
        self.physicsBody?.velocity = .zero
    }
    
    public func setColor(_ color: UIColor) {
        self.shapeNode.fillColor = color
        self.shapeNode.strokeColor = color
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class PongViewController: SceneViewController {

    private let gameAreaAccessibilityView = SpheroPongGameAccessibilityFrame()
    private var playerScoreAccessibilityViews = [UIView]()
    private let messageAccessibilityView = UIView()
    private let winningMessageAccessibilityView = UIView()
    private let playAgainAccessibilityButton = UIButton()
    
    private var landscapeConstraints = [NSLayoutConstraint]()
    private var portraitConstraints = [NSLayoutConstraint]()

    public init() {
        let pongScene = PongScene()
        super.init(scene: pongScene)
        
        pongScene.viewController = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add accessibility views as UIViews because spritekit accessibility is broken.
        gameAreaAccessibilityView.controller = self
        gameAreaAccessibilityView.accessibilityLabel = NSLocalizedString("OriginalPong_PongGameAccessibilityDescription", value: "This is a Pong game. A Sphero sits between two paddles. Run your code to play.", comment: "VoiceOver description of original pong game before game is started.")
        gameAreaAccessibilityView.isAccessibilityElement = true
        gameAreaAccessibilityView.translatesAutoresizingMaskIntoConstraints = false
        gameAreaAccessibilityView.isUserInteractionEnabled = false
        view.addSubview(gameAreaAccessibilityView)
        
        for playerIndex in 0 ..< 2 {
            let scoreView = UIView()
            playerScoreAccessibilityViews.append(scoreView)
            scoreView.isAccessibilityElement = true
            scoreView.translatesAutoresizingMaskIntoConstraints = false
            scoreView.isUserInteractionEnabled = false
            scoreView.accessibilityTraits = UIAccessibilityTraitStaticText
            scoreView.accessibilityHint = String(
                format: NSLocalizedString("OriginalPong_PlayerScoreAccessibilityHint", value: "Player %d's score", comment: "VoiceOver description of the number of points a player has in original pong."),
                playerIndex+1
            )
            setScore(0, forPlayer: playerIndex)
            view.addSubview(scoreView)
            
            let horizontalAttribute: NSLayoutAttribute = playerIndex == 0 ? .left : .right
            
            view.addConstraints([
                NSLayoutConstraint(item: scoreView, attribute: .top, relatedBy: .equal, toItem: liveViewSafeAreaGuide, attribute: .top, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: scoreView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: topBarHeight),
                NSLayoutConstraint(item: scoreView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 100.0),
                NSLayoutConstraint(item: scoreView, attribute: horizontalAttribute, relatedBy: .equal, toItem: liveViewSafeAreaGuide, attribute: horizontalAttribute, multiplier: 1.0, constant: 0.0),
            ])
        }
        
        messageAccessibilityView.translatesAutoresizingMaskIntoConstraints = false
        messageAccessibilityView.isUserInteractionEnabled = false
        view.addSubview(messageAccessibilityView)
        
        winningMessageAccessibilityView.isAccessibilityElement = false
        winningMessageAccessibilityView.translatesAutoresizingMaskIntoConstraints = false
        winningMessageAccessibilityView.isUserInteractionEnabled = false
        winningMessageAccessibilityView.accessibilityTraits = UIAccessibilityTraitStaticText
        view.addSubview(winningMessageAccessibilityView)
        
        playAgainAccessibilityButton.isAccessibilityElement = false
        playAgainAccessibilityButton.translatesAutoresizingMaskIntoConstraints = false
        playAgainAccessibilityButton.isUserInteractionEnabled = false
        playAgainAccessibilityButton.accessibilityTraits = UIAccessibilityTraitButton
        playAgainAccessibilityButton.accessibilityLabel = playAgainMessage
        playAgainAccessibilityButton.addTarget(self, action: #selector(PongViewController.playAgainButtonTapped), for: UIControlEvents.touchUpInside)
        view.addSubview(playAgainAccessibilityButton)
        
        portraitConstraints = [
            NSLayoutConstraint(item: gameAreaAccessibilityView, attribute: .top, relatedBy: .equal, toItem: liveViewSafeAreaGuide, attribute: .top, multiplier: 1.0, constant: topBarHeight)
        ]
        
        landscapeConstraints = [
            NSLayoutConstraint(item: gameAreaAccessibilityView, attribute: .top, relatedBy: .equal, toItem: liveViewSafeAreaGuide, attribute: .top, multiplier: 1.0, constant: 50.0)
        ]
        
        for constraint in portraitConstraints {
            constraint.isActive = false
        }
        
        for constraint in landscapeConstraints {
            constraint.isActive = false
        }
        
        view.addConstraints(portraitConstraints)
        view.addConstraints(landscapeConstraints)
        
        view.addConstraints([
            NSLayoutConstraint(item: gameAreaAccessibilityView, attribute: .bottom, relatedBy: .equal, toItem: liveViewSafeAreaGuide, attribute: .bottom, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: gameAreaAccessibilityView, attribute: .left, relatedBy: .equal, toItem: liveViewSafeAreaGuide, attribute: .left, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: gameAreaAccessibilityView, attribute: .right, relatedBy: .equal, toItem: liveViewSafeAreaGuide, attribute: .right, multiplier: 1.0, constant: 0.0),
            
            NSLayoutConstraint(item: messageAccessibilityView, attribute: .top, relatedBy: .equal, toItem: liveViewSafeAreaGuide, attribute: .top, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: messageAccessibilityView, attribute: .left, relatedBy: .equal, toItem: playerScoreAccessibilityViews[0], attribute: .right, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: messageAccessibilityView, attribute: .right, relatedBy: .equal, toItem: playerScoreAccessibilityViews[1], attribute: .left, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: messageAccessibilityView, attribute: .bottom, relatedBy: .equal, toItem: gameAreaAccessibilityView, attribute: .top, multiplier: 1.0, constant: 0.0),
            
            NSLayoutConstraint(item: winningMessageAccessibilityView, attribute: .centerX, relatedBy: .equal, toItem: liveViewSafeAreaGuide, attribute: .centerX, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: winningMessageAccessibilityView, attribute: .centerY, relatedBy: .equal, toItem: liveViewSafeAreaGuide, attribute: .centerY, multiplier: 1.0, constant: 5.0),
            NSLayoutConstraint(item: winningMessageAccessibilityView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 200.0),
            NSLayoutConstraint(item: winningMessageAccessibilityView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 400.0),
            
            NSLayoutConstraint(item: playAgainAccessibilityButton, attribute: .centerX, relatedBy: .equal, toItem: winningMessageAccessibilityView, attribute: .centerX, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: playAgainAccessibilityButton, attribute: .top, relatedBy: .equal, toItem: winningMessageAccessibilityView, attribute: .bottom, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: playAgainAccessibilityButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 70.0),
            NSLayoutConstraint(item: playAgainAccessibilityButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 300.0)
        ])
        
        (self.scene as? PongScene)?.reset()
        
        NotificationCenter.default.addObserver(self, selector: #selector(PongViewController.applicationWillResignActive), name: .UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PongViewController.applicationDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
    }
    
    func applicationWillResignActive() {
        (self.scene as? PongScene)?.muteSoundMode()
    }
    
    func applicationDidBecomeActive() {
        (self.scene as? PongScene)?.unmuteSoundMode()
    }
    
    public override func updateViewConstraints() {
        
        let isLandscape = view.frame.width > view.frame.height
        
        for constraint in portraitConstraints {
            constraint.isActive = !isLandscape
        }
        
        for constraint in landscapeConstraints {
            constraint.isActive = isLandscape
        }
    
        super.updateViewConstraints()
    }
    
    public func setSoundModeEnabled(_ enabled: Bool) {
        (self.scene as? PongScene)?.setSoundModeEnabled(enabled)
    }
    
    public override func onReceive(message: PlaygroundValue) {
        super.onReceive(message: message)
        
        guard let dict = message.dictValue(),
            let typeId = dict[MessageKeys.type]?.intValue(),
            typeId == MessageTypeId.startPong.rawValue else { return }
        
        if typeId == MessageTypeId.startPong.rawValue {
            
            gameAreaAccessibilityView.accessibilityLabel = NSLocalizedString("OriginalPong_PongGameActiveAccessibilityDescription", value: "Sphero bounces back and forth between two paddles. Double tap and hold to control Player 1's paddle by sliding up and down. If you have trouble seeing Sphero, swipe up with 3 fingers to turn on sound mode.", comment: "VoiceOver description of original pong game while it is active.")
        
            if let pongScene = self.scene as? PongScene {
                
                if let initialBallSpeed = dict[MessageKeys.initialBallSpeed]?.doubleValue() {
                    pongScene.initialBallSpeed = CGFloat(initialBallSpeed)
                }
                
                if let maximumBallSpeed = dict[MessageKeys.maximumBallSpeed]?.doubleValue() {
                    pongScene.maxBallSpeed = CGFloat(maximumBallSpeed)
                }
                
                if let ballSpeedIncrement = dict[MessageKeys.ballSpeedIncrement]?.doubleValue() {
                    pongScene.ballSpeedIncrement = CGFloat(ballSpeedIncrement)
                }
                
                if let leftPaddleColor = dict[MessageKeys.pongLeftPaddleColor]?.colorValue() {
                    pongScene.setPaddle(color: leftPaddleColor, forPlayer:0)
                }
                
                if let rightPaddleColor = dict[MessageKeys.pongRightPaddleColor]?.colorValue() {
                    pongScene.setPaddle(color: rightPaddleColor, forPlayer:1)
                }
                
                if let ballColor = dict[MessageKeys.pongBallColor]?.colorValue() {
                    pongScene.setBall(color: ballColor)
                }
                
                if let backgroundColor = dict[MessageKeys.pongBackgroundColor]?.colorValue() {
                    pongScene.setBackground(color: backgroundColor)
                }
                
                pongScene.startPlaying()
            }
        }
    }
    
    public override func liveViewMessageConnectionClosed() {
        if let pongScene = self.scene as? PongScene {
            pongScene.stopPlaying()
        }
    }
    
    public func sendFinishedMessage() {
        sendMessageToContents(.dictionary([MessageKeys.type:MessageTypeId.pongEnded.playgroundValue()]))
    }
    
    public func setMessageText(_ text: String) {
        messageAccessibilityView.accessibilityLabel = text
        messageAccessibilityView.isAccessibilityElement = !text.isEmpty
    }
    
    public func setScore(_ score: Int, forPlayer playerIndex: Int) {
        playerScoreAccessibilityViews[playerIndex].accessibilityLabel = "\(score)"
    }
    
    public func gameFinished(message: String) {
        self.gameAreaAccessibilityView.isAccessibilityElement = false
        
        self.winningMessageAccessibilityView.isAccessibilityElement = true
        self.playAgainAccessibilityButton.isAccessibilityElement = true
        
        self.winningMessageAccessibilityView.accessibilityLabel = message
        
        sendFinishedMessage()
    }
    
    public func playAgainButtonTapped(sender:UIButton!) {
        (self.scene as? PongScene)?.playAgain()
    }
    
    public func reset() {
        self.gameAreaAccessibilityView.isAccessibilityElement = true
        setScore(0, forPlayer: 0)
        setScore(0, forPlayer: 1)
        
        self.winningMessageAccessibilityView.isAccessibilityElement = false
        self.playAgainAccessibilityButton.isAccessibilityElement = false
    }
}

class SpheroPongGameAccessibilityFrame: UIView {
    public weak var controller: PongViewController?
    
    public override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        
        if direction == .down {
            controller?.setSoundModeEnabled(true)
            return true
        }
        
        if direction == .up {
            controller?.setSoundModeEnabled(false)
            return true
        }
        
        return false
    }
}

extension UIBezierPath {
    public func bolt(to toPoint: CGPoint) {
        let fromPoint = currentPoint
        let distance = hypot(toPoint.y - fromPoint.y, toPoint.x - fromPoint.x)
        
        if distance < 10.0 {
            addLine(to: toPoint)
            return
        }
        
        var midX = (fromPoint.x + toPoint.x) / 2
        var midY = (fromPoint.y + toPoint.y) / 2
        
        midX += CGFloat(Double.random() - 0.5) * distance / 3.0
        midY += CGFloat(Double.random() - 0.5) * distance / 3.0
        
        bolt(to: CGPoint(x: midX, y: midY))
        bolt(to: toPoint)
    }
}
