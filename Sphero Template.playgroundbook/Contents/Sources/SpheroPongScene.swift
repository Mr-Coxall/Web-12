//
//  SpheroPongScene.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-30.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import SpriteKit
import PlaygroundSupport

private let screenSize = UIScreen.main.bounds.size
private let maxScreenSize = max(screenSize.width, screenSize.height)
private let boldFontName = UIFont.boldSystemFont(ofSize: 10.0).fontName

private let scoreCardSize = CGSize(width: 430, height: 220)

private let scoreCardDisplacementSceneWidthThreshold: CGFloat = 600.0

private let resultsLabelTextFormat = NSLocalizedString("SpheroPong_WinningMessage",
    value: "PLAYER %d WINS!",
    comment: "Message when a player wins Sphero pong. %d is replaced with 1 or 2."
)

public class SpheroPongScene: SKScene {
    
    private let mangaLineContainerNode = SKNode()
    
    private var mangaLinesNodes = [SKSpriteNode]()
    
    private let dashedLinePeriod: CGFloat = 70
    
    private let spheroNode = SKSpriteNode(imageNamed: "spheroBody")
    private let spheroFaceNode = SKSpriteNode(imageNamed: "spheroFace")
    
    private let backgroundNode = SKSpriteNode(texture: SKTexture(imageNamed: "spheroPongBg"))
    
    typealias BackgroundAssetSet = (color: UIColor, mangaLines: SKTexture)
    
    private var ballSpeed: CGFloat = 0.0
    
    private let scoreCardContainerNode = SKNode()
    private let scoreCardNode = SKShapeNode(rectOf: scoreCardSize, cornerRadius: 10.0)
    
    private var scores: [Int] = [0, 0]
    
    private let scoreLabels = [
        SKLabelNode(fontNamed: UIFont.arcadeFontName),
        SKLabelNode(fontNamed: UIFont.arcadeFontName)
    ]
    
    private let playerLabels = [
        SKLabelNode(fontNamed: UIFont.arcadeFontName),
        SKLabelNode(fontNamed: UIFont.arcadeFontName)
    ]
    
    private let playerFaceNodes = [
        SKSpriteNode(imageNamed: "spheroFace"),
        SKSpriteNode(imageNamed: "spheroFace"),
        ]
    
    private let playerFaceBackgroundNodes = [
        SKShapeNode(circleOfRadius: 33.0),
        SKShapeNode(circleOfRadius: 33.0),
        ]
    
    private var playerColors: [UIColor?] = [nil,nil]
    
    private let playerNodeOffsetX: CGFloat = 100.0
    
    private var collisionFrames: [SKTexture] = []
    private let collisionNode: SKSpriteNode
    
    private var toyRollOrientation: CGFloat = 0.0
    
    private var shouldShowCollisionOnNextRoll = false
    
    private let resultsNode = SKShapeNode(rectOf: CGSize(width: maxScreenSize, height: maxScreenSize))
    
    private let timerNode = SKShapeNode(rectOf: CGSize(width: maxScreenSize, height: maxScreenSize))
    private let timerClockNode = SKSpriteNode(imageNamed: "timer_base")
    private let timerShapeNode = SKShapeNode()
    private let timerHandNode = SKSpriteNode(imageNamed: "time_pointer")
    private let timerCountNode = SKLabelNode(fontNamed: UIFont.arcadeFontName)
    
    private let timerExplanationNodeTop = AutoshrinkLabelNode(fontNamed: boldFontName)
    private let timerExplanationNodeBottom = AutoshrinkLabelNode(fontNamed: boldFontName)
    
    private let timerTitleNode = AutoshrinkLabelNode(fontNamed: UIFont.arcadeFontName)
    
    private var isShowingTimer = false
    
    public weak var safeAreaContainer: SafeFrameContainer?
    
    private let rotationNode = SKNode()
    private let gameNode = SKNode()
    
    private var currentPlayerIndex = 0
    
    private let speaker = AccessibilitySpeechQueue()
    
    private let winSound = Sound("Celebrate")
    private let scoreSound = Sound("Cheering")
    private let bongSound = Sound("Brass-Bell")
    private let tickSound = Sound("Click", volume: 0.1)
    private let dingSound = Sound("Bell")
    private let collisionSound = Sound("ButtonPulse")
    
    public override init(size: CGSize) {
        
        for i in 1 ... 6 {
            collisionFrames.append(SKTexture(imageNamed: "collision0\(i)"))
        }
        collisionNode = SKSpriteNode(texture: collisionFrames[0])
        collisionNode.zPosition = 0
        collisionNode.position.x = -100.0
        collisionNode.alpha = 0
        
        super.init(size: size)
        
        gameNode.addChild(rotationNode)
        rotationNode.addChild(collisionNode)
        
        let camera = SKCameraNode()
        gameNode.addChild(camera)
        self.camera = camera
        
        let scoreColor = scoreCardColor(self.backgroundColor)
        scoreCardNode.fillColor = scoreColor
        scoreCardNode.strokeColor = scoreColor
        scoreCardNode.isHidden = true
        
        scoreCardContainerNode.addChild(scoreCardNode)
        
        // Add the score card to the camera node so it moves with it.
        gameNode.addChild(scoreCardContainerNode)
        
        for (i, scoreLabel) in scoreLabels.enumerated() {
            scoreLabel.fontSize = 100.0
            scoreLabel.text = "0"
            scoreLabel.position.x = (i == 0 ? -playerNodeOffsetX : playerNodeOffsetX) + 20.0
            scoreLabel.position.y = -50.0
            scoreCardNode.addChild(scoreLabel)
        }
        
        for (i, playerLabel) in playerLabels.enumerated() {
            playerLabel.fontSize = 18.0
            playerLabel.text = String(
                format: NSLocalizedString("SpheroPong_PlayerLabel",
                                          value: "PLAYER %d",
                                          comment: "Label under players' scores in Sphero pong. %d is replaced with 1 or 2."
                ),
                i+1
            )
            playerLabel.position.x = i == 0 ? -playerNodeOffsetX : playerNodeOffsetX
            playerLabel.position.y = -85.0
            scoreCardNode.addChild(playerLabel)
        }
        
        let vsLabel = AutoshrinkLabelNode(fontNamed: UIFont.arcadeFontName)
        vsLabel.fontColor = UIColor(white: 0.0, alpha: 0.4)
        vsLabel.fontSize = 26.0
        vsLabel.text = NSLocalizedString("SpheroPong_VS", value: "VS", comment: "Label in between the 2 players' labels (PLAYER 1 and PLAYER 2) in Sphero pong")
        vsLabel.position.y = -50.0
        vsLabel.maxWidth = 80.0
        scoreCardNode.addChild(vsLabel)
        
        for (i, faceNode) in playerFaceNodes.enumerated() {
            faceNode.position.x = (i == 0 ? -playerNodeOffsetX : playerNodeOffsetX) - 30.0
            faceNode.position.y = -45.0
            faceNode.xScale = 0.5
            faceNode.yScale = 0.5
            faceNode.zPosition = 1.0
            scoreCardNode.addChild(faceNode)
            
            let backgroundNode = playerFaceBackgroundNodes[i]
            backgroundNode.fillColor = .white
            backgroundNode.strokeColor = .white
            backgroundNode.zPosition = -0.5
            backgroundNode.position.x = 4.0
            faceNode.addChild(backgroundNode)
        }
        
        self.scaleMode = .resizeFill
        
        for i in 0 ..< 2 {
            let mangaNode = SKSpriteNode(texture: SKTexture(imageNamed: "mangaLines"))
            mangaNode.zPosition = 0.5
            mangaNode.position.x = CGFloat(i) * mangaNode.size.width
            // Manga lines were scaled down to decrease file size.
            // mangaNode.xScale = 2
            // mangaNode.yScale = 2
            backgroundNode.addChild(mangaNode)
            mangaLinesNodes.append(mangaNode)
        }
        
        spheroNode.zPosition = 1
        spheroNode.addChild(spheroFaceNode)
        spheroFaceNode.position.x = 10
        
        gameNode.addChild(spheroNode)
        
        backgroundNode.zPosition = -2
        rotationNode.addChild(backgroundNode)
        
        resultsNode.zPosition = 10
        
        timerNode.zPosition = 10
        timerNode.fillColor = UIColor(white: 0.0, alpha: 0.85)
        timerNode.strokeColor = timerNode.fillColor
        
        timerClockNode.position.y = 15.0
        timerClockNode.zPosition = 1
        timerNode.addChild(timerClockNode)
        
        let timerLinesNode = SKSpriteNode(imageNamed: "timer_lines")
        timerLinesNode.position.y = -12.0
        timerLinesNode.zPosition = 3
        timerClockNode.addChild(timerLinesNode)
        
        timerHandNode.zPosition = 3
        timerHandNode.position.y = -12.0
        timerClockNode.addChild(timerHandNode)
        
        // Use the inverted color of what the shape node actually is,
        // set blend mode to subtractive.
        // This ensures it doesn't get drawn over the black clock outline.
        timerShapeNode.fillColor = #colorLiteral(red: 0.09803921569, green: 0.6666666667, blue: 0.7803921569, alpha: 1)
        timerShapeNode.strokeColor = #colorLiteral(red: 0.09803921569, green: 0.6666666667, blue: 0.7803921569, alpha: 1)
        timerShapeNode.zPosition = 2
        timerShapeNode.position.y = -12.0
        timerShapeNode.blendMode = .subtract
        timerClockNode.addChild(timerShapeNode)
        
        timerCountNode.zPosition = 4
        timerCountNode.fontSize = 32
        timerCountNode.position.y = -22.0
        timerClockNode.addChild(timerCountNode)
        
        timerTitleNode.position.y = 140.0
        timerTitleNode.fontSize = 32.8
        timerTitleNode.text = NSLocalizedString("SpheroPong_ResetMessageTitle", value: "TIME TO RESET!", comment: "Title of message prompting user to place Sphero in the middle of the playfield")
        timerTitleNode.fontColor = .white
        timerNode.addChild(timerTitleNode)
        
        timerExplanationNodeTop.position.y = -110
        timerExplanationNodeTop.fontSize = 18.0
        timerExplanationNodeTop.fontColor = .white
        timerNode.addChild(timerExplanationNodeTop)
        
        timerExplanationNodeBottom.position.y = -136
        timerExplanationNodeBottom.fontSize = 18.0
        timerExplanationNodeBottom.fontColor = .white
        timerNode.addChild(timerExplanationNodeBottom)
        
        addChild(gameNode)
    }
    
    public func reset() {
        removeAllChildren()
        showGame()
        scoreCardNode.isHidden = true
        
        toyRollOrientation = 0.0
        for i in 0 ..< 2 {
            setScore(0, forPlayer: i)
        }
        setSpeed(0.0, direction: 0.0)
        
        resultsNode.removeAllChildren()
    }
    
    private func showGame() {
        if resultsNode.parent != nil {
            resultsNode.removeFromParent()
        }
        
        if gameNode.parent == nil {
            addChild(gameNode)
        }
        
        scaleMode = .resizeFill
        if let view = view {
            size = view.frame.size
        }
    }
    
    public override convenience init() {
        let screenSize = UIScreen.main.bounds
        let size = max(screenSize.width, screenSize.height)
        self.init(size: CGSize(width:size, height: size))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func update(_ currentTime: TimeInterval) {
        for mangaNode in mangaLinesNodes {
            mangaNode.position.x -= 25.0 + ballSpeed / 255.0 * 200.0
            
            if mangaNode.position.x < -mangaNode.size.width / mangaNode.xScale {
                mangaNode.position.x += 2*mangaNode.size.width / mangaNode.xScale
            }
        }
        
        let s = sin(CGFloat(currentTime)*ballSpeed/7.5)
        spheroNode.yScale = (s*0.01) + (1.0 - ballSpeed * 0.2 / 255.0)
        
        if isShowingTimer {
            let timerPath = UIBezierPath()
            
            let timerRadius: CGFloat = 65
            timerPath.move(to: .zero)
            timerPath.addLine(to: CGPoint(x: 0, y: timerRadius))
            timerPath.addArc(withCenter: .zero, radius: timerRadius, startAngle: .pi / 2.0, endAngle: timerHandNode.zRotation - .pi / 3.0, clockwise: false)
            timerPath.close()
            
            timerShapeNode.path = timerPath.cgPath
        }
    }
    
    public func setCurrentPlayer(index: Int) {
        currentPlayerIndex = index
    }
    
    private func scoreCardColor(_ color: UIColor) -> UIColor {
        
        var hue: CGFloat = 0.0
        var saturation: CGFloat = 0.0
        var brightness: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        return UIColor(hue: hue, saturation: saturation, brightness: brightness * 0.95, alpha: alpha*0.7)
    }
    
    private func faceColor(_ color: UIColor) -> UIColor {
        
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        red = min(1,red*1.2)
        green = min(1,green*1.2)
        blue = min(1,blue*1.2)
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    public func onRoll(speed: CGFloat, direction: CGFloat) {
        if speed == 0 { return }
        
        setSpeed(speed, direction: direction)
    }
    
    public func setSpeed(_ speed: CGFloat, direction: CGFloat) {
        let relativeDirection = direction + toyRollOrientation
        
        // Sphero & rotation nodes need to be rotated separately
        // so that the Sphero can be moved down when the score card is lowered due to safe area.
        rotationNode.zRotation = -relativeDirection
        spheroNode.zRotation = -relativeDirection
        
        // Undo rotation from Sphero's face
        spheroFaceNode.zRotation = relativeDirection
        
        ballSpeed = speed
        
        if shouldShowCollisionOnNextRoll {
            shouldShowCollisionOnNextRoll = false
            self.collisionNode.alpha = 1.0
            self.collisionNode.zRotation = CGFloat(arc4random_uniform(360)) * .pi / 180.0
            
            let action = SKAction.sequence([
                SKAction.animate(with: collisionFrames, timePerFrame: 1.0/30.0),
                SKAction.run({
                    self.collisionNode.alpha = 0.0
                })
                ])
            self.collisionNode.run(action)
        }
        
        if speed != 0 {
            if let color = playerColors[currentPlayerIndex] {
                backgroundColor = color
                
                let scoreCardColor = self.scoreCardColor(color)
                scoreCardNode.strokeColor = scoreCardColor
                scoreCardNode.fillColor = scoreCardColor
            }
            
            let otherPlayerNumber = currentPlayerIndex == 0 ? 2 : 1
            
            let message = String(
                format: NSLocalizedString("SpheroPong_AccessibilityRollMessage",
                                          value: "Sphero rolls at Player %d",
                                          comment: "VoiceOver message when Sphero rolls towards a player in Sphero pong."
                ),
                otherPlayerNumber
            )
            
            speaker.speak(message)
        }
    }
    
    public override func didChangeSize(_ oldSize: CGSize) {
        var yOffset: CGFloat = 0.0
        
        if let safeFrame = self.safeAreaContainer?.liveViewSafeAreaFrame {
            yOffset = max(0.0, safeFrame.minY - 15)
        }
        
        let cameraScale = max(1.0, 512.0/min(size.height, size.width))
        
        // If there isn't room for the BT connection status beside the scoreboard, move the scoreboard down to allow the connection status to be on top of it.
        if size.width < scoreCardDisplacementSceneWidthThreshold {
            yOffset += 55.0
        }
        
        camera?.xScale = cameraScale
        camera?.yScale = cameraScale
        
        self.scoreCardNode.position.y = (size.height / 2.0 - 32 - yOffset) * cameraScale
        self.spheroNode.position.y = -yOffset * cameraScale
    }
    
    public func setFace(color: UIColor, forPlayer playerIndex: Int) {
        playerColors[playerIndex] = color
        
        let faceColor = self.faceColor(color)
        
        playerFaceBackgroundNodes[playerIndex].fillColor = faceColor
        playerFaceBackgroundNodes[playerIndex].strokeColor = faceColor
    }
    
    public func player(index playerIndex: Int, scored points: Int) {
        bongSound.play()
    
        setScore(scores[playerIndex] + points, forPlayer: playerIndex)
        
        toyRollOrientation = playerIndex == 1 ? 0.0 : CGFloat.pi
        
        let bounceAction = SKAction.sequence([
            SKAction.group([
                SKAction.move(by: CGVector(dx: 0.0, dy: 20.0), duration: 0.2),
                SKAction.rotate(toAngle: .pi/5, duration: 0.2)
                ]),
            SKAction.group([
                SKAction.move(by: CGVector(dx: 0.0, dy: -20.0), duration: 0.2),
                SKAction.rotate(toAngle: 0, duration: 0.2)
                ]),
            SKAction.run({
                self.cutTo(color: self.playerColors[playerIndex] ?? .lightGray) {
                    self.showScoreAnimation(playerIndex: playerIndex)
                }
            })
            ])
        
        bounceAction.timingFunction = {
            time in
            return (pow(2*time-1, 3.0) + 1) / 2.0
        }
        
        playerFaceNodes[playerIndex].run(bounceAction)
    }
    
    private func showScoreAnimation(playerIndex: Int) {
        
        let happySpheroNode = SKSpriteNode(imageNamed: "frontHappy")
        happySpheroNode.zPosition = 1
        
        let shadowNode = SKSpriteNode(imageNamed: "shadow")
        shadowNode.position.y = -180
        
        let scoreLabel = SKLabelNode(text: "\(scores[playerIndex] - 1)")
        scoreLabel.position.y = 30
        scoreLabel.fontName = UIFont.arcadeFontName
        scoreLabel.fontSize = 99.0
        
        let scoringMessage = String(
            format: NSLocalizedString("SpheroPong_ScoringMessage",
                                      value: "PLAYER %d\nSCORES!",
                                      comment: "Scoring message for Sphero pong. %d is replaced with 1 or 2."
            ),
            playerIndex+1
        )
        
        let scoringMessageLines = scoringMessage.components(separatedBy: "\n")
        let scoringMessageTopLine = scoringMessageLines.count >= 1 ? scoringMessageLines[0] : ""
        let scoringMessageBottomLine = scoringMessageLines.count >= 2 ? scoringMessageLines[1] : ""
        
        let isVerticallyCompact = size.height < 600.0
        let messageLabelTop = SKLabelNode(text: scoringMessageTopLine)
        messageLabelTop.position.y = 200
        messageLabelTop.fontName = UIFont.arcadeFontName
        messageLabelTop.fontSize = 46.0
        messageLabelTop.isHidden = isVerticallyCompact
        
        let messageLabelBottom = SKLabelNode(text: scoringMessageBottomLine)
        messageLabelBottom.position.y = 150
        messageLabelBottom.fontName = UIFont.arcadeFontName
        messageLabelBottom.fontSize = 46.0
        messageLabelBottom.isHidden = isVerticallyCompact
        
        addChild(happySpheroNode)
        addChild(shadowNode)
        addChild(scoreLabel)
        addChild(messageLabelTop)
        addChild(messageLabelBottom)
        
        let fallDuration: TimeInterval = 0.65
        let bottomSquishDuration: TimeInterval = 0.25
        let jumpToScoreDuration: TimeInterval = 0.15
        let topSquishDuration: TimeInterval = 0.20
        let fallFromScoreDuration: TimeInterval = 0.1
        
        let spheroY: CGFloat = -115
        let squishFactor: CGFloat = 0.85
        
        let spheroJumpDistance = 80.0
        
        shadowNode.alpha = 0.0
        shadowNode.xScale = 0.0
        shadowNode.yScale = 0.0
        
        shadowNode.run(
            .sequence([
                .group([
                    .fadeAlpha(to: 1.0, duration: fallDuration),
                    .scale(to: 0.9, duration: fallDuration)
                    ]),
                .wait(forDuration: bottomSquishDuration),
                .group([
                    .fadeAlpha(to: 0.5, duration: jumpToScoreDuration),
                    .scale(to: 0.4, duration: jumpToScoreDuration)
                    ]),
                .wait(forDuration: topSquishDuration),
                .group([
                    .fadeAlpha(to: 1.0, duration: fallFromScoreDuration),
                    .scale(to: 0.9, duration: fallFromScoreDuration)
                    ])
                ])
        )
        
        for label in [scoreLabel, messageLabelTop, messageLabelBottom] {
            label.alpha = 0.0
            label.run(
                .sequence([
                    // Fade in from top to bottom
                    .wait(forDuration: (300 - Double(label.position.y)) / 500),
                    .fadeAlpha(to: 1.0, duration: 0.5)
                    ])
            )
        }
        
        happySpheroNode.position.y = 512 + happySpheroNode.size.height / 2.0
        let fallIn = SKAction.move(to: CGPoint(x: 0, y:spheroY), duration: fallDuration)
        // Fall in a parabola
        fallIn.timingFunction = { (time: Float) in
            return time * time
        }
        
        let squishDown = SKAction.squishWithHeight(happySpheroNode.size.height, toFactor: squishFactor, up: false, duration: bottomSquishDuration)
        
        let jumpToScore = SKAction.move(by: CGVector(dx: 0, dy: spheroJumpDistance), duration: jumpToScoreDuration)
        jumpToScore.timingFunction = { (time: Float) in
            // Start fast & slow down
            return 0.5 * time * (3.0 - time)
        }
        
        let incrementScore = SKAction.run {
            let scoreSquishUp = SKAction.squishWithHeight(scoreLabel.fontSize, toFactor: squishFactor, up: true, duration: topSquishDuration)
            
            self.scoreSound.play()
            
            scoreLabel.run(.group([
                scoreSquishUp,
                .sequence([
                    .fadeAlpha(to: 0.5, duration: topSquishDuration / 2.0),
                    .run({
                        scoreLabel.text = "\(self.scores[playerIndex])"
                    }),
                    .fadeAlpha(to: 1.0, duration: topSquishDuration / 2.0)
                    ])
                ]))
        }
        
        let squishUp = SKAction.squishWithHeight(happySpheroNode.size.height + scoreLabel.fontSize, toFactor: squishFactor, up: true, duration: topSquishDuration)
        
        let fallFromScore = SKAction.move(by: CGVector(dx: 0, dy: -spheroJumpDistance), duration: fallFromScoreDuration)
        
        let stars = SKAction.run {
            self.makeStars(behind: happySpheroNode)
        }
        
        happySpheroNode.run(.sequence([fallIn, squishDown, jumpToScore, incrementScore, squishUp, fallFromScore, stars, squishDown]))
        
        let playerNumber = playerIndex+1
        
        let voiceOverMessage = String(
            format: NSLocalizedString("SpheroPong_AccessibilityScorePointMessage",
                                      value: "Player %1$d scored.  Sphero drops in from above, bounces off the floor and hits Player %1$d's score, changing it from %3$d to %2$d",
                                      comment: "VoiceOver message when a player scores a point in Sphero Pong."
            ),
            playerNumber,
            scores[playerIndex],
            scores[playerIndex]-1
        )
        
        speaker.speak(voiceOverMessage)
    }
    
    private func makeStars(behind sphero: SKNode) {
        
        let starNames = ["star1", "star2", "star3"]
        let trailNames = ["trail1", "trail2", "trail3"]
        
        // Hey now
        let allStars = SKNode()
        
        let starCount = 20
        
        for i in 0 ..< starCount {
            let containerNode = SKNode()
            
            let starNode = SKSpriteNode(imageNamed: starNames[i % starNames.count])
            let trailNode = SKSpriteNode(imageNamed: trailNames[i % trailNames.count])
            
            trailNode.blendMode = .add
            
            trailNode.position.x = -trailNode.size.width / 2.0
            trailNode.position.y = -trailNode.size.height / 2.0
            
            containerNode.addChild(starNode)
            containerNode.addChild(trailNode)
            
            let delay = Double.random() * 0.2
            let wait = SKAction.wait(forDuration: delay)
            
            let zRotation = CGFloat(i) / CGFloat(starCount-1) * CGFloat.pi // CGFloat(Double.random() * .pi)
            containerNode.zRotation = zRotation
            
            containerNode.alpha = CGFloat(Double.random() * 0.65 + 0.25)
            
            allStars.addChild(containerNode)
            
            let fade = SKAction.fadeOut(withDuration: 0.5)
            
            trailNode.run(.sequence([wait, fade]))
            
            starNode.run(
                .sequence([
                    wait,
                    .rotate(byAngle: CGFloat(Double.random()-0.5) * 4.0 * CGFloat.pi, duration: 1.0)
                    ])
            )
            
            // Space every 2nd star further so they cover the space around the Sphero well.
            let distance = CGFloat(Double.random() * 75.0) + 60*CGFloat(i%2) + 90
            let destination = CGPoint(x: cos(zRotation)*distance, y: sin(zRotation)*distance)
            
            let moveAway = SKAction.move(to: destination, duration: 0.5)
            moveAway.timingFunction = { time in
                return 1.0 - pow(1.0 - time, 3)
            }
            
            containerNode.run(.sequence([
                wait,
                moveAway,
                .fadeOut(withDuration: 0.5)
                ]))
        }
        
        allStars.position = sphero.position
        addChild(allStars)
        
        allStars.run(.sequence([
            .move(by: CGVector(dx: 0, dy:-100), duration: 2.0),
            .run({
                allStars.removeFromParent()
            })
            ]))
    }
    
    public func setScore(_ score: Int, forPlayer playerIndex: Int) {
        scores[playerIndex] = score
        scoreLabels[playerIndex].text = "\(scores[playerIndex])"
    }
    
    public func getScore(forPlayer playerIndex: Int) -> Int {
        return scores[playerIndex]
    }
    
    public func showCollision() {
        // Wait until the roll command before showing the collision, otherwise the animation will jump when the camera angle changes.
        self.shouldShowCollisionOnNextRoll = true
        collisionSound.play()
    }
    
    public func showWinner(playerIndex: Int) {
        cutTo(color: playerColors[playerIndex] ?? .lightGray) {
            self.addChild(self.resultsNode)
            
            self.scaleMode = .aspectFill
            self.size = CGSize(width: 768, height: 512)
            
            let floorNodeHeight: CGFloat = 185.0
            let floorNode = SKShapeNode(rectOf: CGSize(width: self.size.width, height: floorNodeHeight))
            floorNode.position.y = (floorNodeHeight-self.size.height) / 2.0
            floorNode.fillColor = self.backgroundColor
            floorNode.strokeColor = self.backgroundColor
            floorNode.zPosition = 1.0
            self.resultsNode.addChild(floorNode)
            
            let bottomNodeHeight: CGFloat = 138
            let bottomNode = SKShapeNode(rectOf: CGSize(width: self.size.width, height: bottomNodeHeight))
            bottomNode.fillColor = UIColor(white: 0.0, alpha: 0.08)
            bottomNode.strokeColor = bottomNode.fillColor
            bottomNode.position.y = -(bottomNodeHeight+self.size.height) / 2.0
            bottomNode.zPosition = 2
            
            let moveIn = SKAction.move(by: CGVector(dx:0.0, dy:bottomNodeHeight), duration: 0.5)
            moveIn.timingFunction = { (time: Float) in
                return time * (2 - time)
            }
            bottomNode.run(moveIn)
            self.resultsNode.addChild(bottomNode)
            
            let lineNode = SKShapeNode(rectOf: CGSize(width: self.size.width, height: 4.0))
            lineNode.fillColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.6)
            lineNode.strokeColor = .clear
            lineNode.position.y = -71
            lineNode.alpha = 0.0
            lineNode.zPosition = 2
            
            lineNode.run(.fadeAlpha(to: 1.0, duration: 1.0))
            self.resultsNode.addChild(lineNode)
            
            let trophyNode = SKSpriteNode(imageNamed: "cup")
            trophyNode.position.y = (self.size.height+trophyNode.size.height)/2.0
            trophyNode.zPosition = 4
            
            let fallIn = SKAction.move(to: CGPoint(x: 0, y: 14.5), duration: 0.5)
            fallIn.timingFunction = { (time: Float) in
                return time * time
            }
            
            trophyNode.run(
                .sequence([
                    .wait(forDuration: 0.1),
                    fallIn,
                    .run({
                        self.winSound.play()
                        if let particleNode = SKEmitterNode(fileNamed: "WinningParticle") {
                            particleNode.zPosition = 3
                            self.resultsNode.addChild(particleNode)
                        }
                    }),
                    .squishWithHeight(trophyNode.size.height, toFactor: 0.85, up: false, duration: 0.25),
                    ])
            )
            self.resultsNode.addChild(trophyNode)
            
            let path = UIBezierPath()
            
            var isUp = false
            
            let downDistance: CGFloat = 20.0
            let upDistance = self.size.width
            
            path.move(to: CGPoint(x: downDistance, y: 0.0))
            
            let angleCount = 200
            
            // Don't allow bands to be too thick.
            let maxChangeDistance = 10
            
            var lastChange = 0
            
            for i in 1 ... angleCount {
                let angle = CGFloat(i) * CGFloat.pi * 2.0 / CGFloat(angleCount)
                
                let unitX = cos(angle)
                let unitY = sin(angle)
                
                var distance = isUp ? upDistance : downDistance
                
                path.addLine(to: CGPoint(x: distance * unitX, y: distance * unitY))
                
                // Make it more likely to go back down.
                if (i - lastChange >= maxChangeDistance) || arc4random_uniform(isUp ? 3 : 5) == 0 {
                    isUp = !isUp
                    
                    distance = isUp ? upDistance : downDistance
                    path.addLine(to: CGPoint(x: distance * unitX, y: distance * unitY))
                    
                    lastChange = i
                }
            }
            
            path.close()
            
            let pathNode = SKShapeNode(path: path.cgPath)
            
            pathNode.fillColor = UIColor(white: 1.0, alpha: 0.2)
            pathNode.strokeColor = .clear
            pathNode.zPosition = 0
            pathNode.alpha = 0
            pathNode.position.y = -200
            
            let pathBody = SKPhysicsBody()
            pathBody.affectedByGravity = false
            pathBody.linearDamping = 0.0
            pathBody.angularDamping = 0.0
            pathBody.angularVelocity = -0.2
            
            pathNode.physicsBody = pathBody
            
            pathNode.run(
                .sequence([
                    .wait(forDuration: 1.0),
                    .fadeAlpha(to: 1.0, duration: 1.0)
                    ])
            )
            
            self.resultsNode.addChild(pathNode)
            
            let resultsLabelNode = AutoshrinkLabelNode(fontNamed: UIFont.arcadeFontName)
            
            resultsLabelNode.color = .white
            resultsLabelNode.fontSize = 24.0
            resultsLabelNode.position.y = -150
            resultsLabelNode.zPosition = 3.0
            resultsLabelNode.text = String(
                format: resultsLabelTextFormat,
                playerIndex+1
            )
            
            resultsLabelNode.alpha = 0.0
            resultsLabelNode.run(
                .sequence([
                    .wait(forDuration: 0.2),
                    .fadeAlpha(to: 1.0, duration: 1.0)
                    ])
            )
            
            self.resultsNode.addChild(resultsLabelNode)
            if let frame = self.view?.frame {
                resultsLabelNode.maxWidth = frame.width * self.size.height / frame.height - 40.0
            }
        }
        
        let playerNumber = playerIndex + 1
        
        let message = String(
            format: NSLocalizedString("SpheroPong_AccessibilityWinMessage",
                                      value: "Player %d wins",
                                      comment: "VoiceOver message when a player wins a game of Sphero pong. %d is replaced with 1 or 2 depending on who won."
            ),
            playerNumber
        )
        
        speaker.speak(message)
    }
    
    public func hideScoreCard() {
        self.scoreCardNode.isHidden = true
    }
    
    public func showTimer(for time: TimeInterval) {
        
        setSpeed(0, direction: 0)
        
        if timerNode.parent == nil {
            addChild(timerNode)
        }
        
        let cameraScale: CGFloat
        if let camera = camera {
            cameraScale = camera.xScale
        } else {
            cameraScale = 1.0
        }
        
        let isVeryCompact = size.height < 420.0
        let maxLabelWidth = size.width * cameraScale - 40.0
        timerTitleNode.maxWidth = maxLabelWidth
        timerTitleNode.isHidden = isVeryCompact
        timerExplanationNodeTop.maxWidth = maxLabelWidth
        timerExplanationNodeBottom.maxWidth = maxLabelWidth
        
        timerNode.zPosition = 100.0
        timerNode.alpha = 0.0
        timerNode.run(.fadeAlpha(to: 1.0, duration: 0.2))
        
        let timesAndNodes : [(TimeInterval, SKNode)] = [(0.2, timerClockNode), (0.3, timerTitleNode), (0.4, timerExplanationNodeTop), (0.5, timerExplanationNodeBottom)]
        for (waitTime,node) in timesAndNodes {
            node.position.x = -700.0
            
            let moveIn = SKAction.move(to: CGPoint(x: 50.0, y: node.position.y), duration: 0.3)
            moveIn.timingFunction = { (time: Float) in
                return time * (2.0 - time)
            }
            
            let correct = SKAction.move(to: CGPoint(x: 0.0, y: node.position.y), duration: 0.15)
            correct.timingFunction = { (time: Float) in
                return time * time * (3.0 - 2.0 * time)
            }
            
            node.run(
                .sequence([
                    .wait(forDuration: waitTime),
                    moveIn,
                    correct
                    ])
            )
        }
        
        isShowingTimer = true
        
        spheroNode.isHidden = true
        
        timerHandNode.zRotation = 5.0 * CGFloat.pi / 6.0
        timerHandNode.run(SKAction.sequence([
            SKAction.rotate(byAngle: -2.0 * .pi, duration: time),
            SKAction.run({
                self.hideTimer()
                self.dingSound.play()
            })
            ]))
        
        var countdownActions = [SKAction]()
        
        countdownActions.append(SKAction.wait(forDuration: time.truncatingRemainder(dividingBy: 1.0)))
        
        for i in stride(from: Int(time), through: 1, by: -1) {
            countdownActions.append(SKAction.run({
                let text = "\(min(9,i))"
                self.timerCountNode.text = text
                self.tickSound.play()
                if !self.speaker.isSpeaking {
                    self.speaker.speak(text)
                }
            }))
            countdownActions.append(SKAction.wait(forDuration: 1.0))
        }
        
        timerCountNode.run(SKAction.sequence(countdownActions))
        
        let otherPlayerNumber = currentPlayerIndex == 0 ? 2 : 1
        let currentPlayerNumber = currentPlayerIndex == 0 ? 1 : 2
        
        let message = String(
            format: NSLocalizedString(
                "SpheroPong_AccessibilityRestartVolleyMessage",
                value: "Place Sphero in front of Player %d and aim it at Player %d",
                comment: "VoiceOver message for restarting volley in Sphero pong. %d is replaced with 1 or 2."
            ),
            currentPlayerNumber,
            otherPlayerNumber
        )
        
        speaker.speak(message)
        
        let splitMessage = String(
            format: NSLocalizedString(
                "SpheroPong_ResetMessage",
                value: "Place Sphero in front of Player %d\nand aim it at Player %d",
                comment: "VoiceOver message for restarting volley in Sphero pong. %d is replaced with 1 or 2."
            ),
            currentPlayerNumber,
            otherPlayerNumber
        )
        
        
        let resetMessage = splitMessage
        
        let lines = resetMessage.components(separatedBy: "\n")
        let topLine = lines.count >= 1 ? lines[0] : ""
        let bottomLine = lines.count >= 2 ? lines[1] : ""

        timerExplanationNodeTop.text = topLine
        timerExplanationNodeBottom.text = bottomLine
    }
    
    public func hideTimer() {
        if !isShowingTimer { return }
        
        // Need to remove these or SpriteKit will run them as soon as they get re-added to the scene.
        for node: SKNode in [timerNode, timerHandNode, timerCountNode, timerClockNode, timerTitleNode, timerExplanationNodeTop, timerExplanationNodeBottom] {
            node.removeAllActions()
        }
        
        removeAllChildren()
        addChild(self.gameNode)
        
        isShowingTimer = false
        spheroNode.isHidden = false
    }
    
    public func start() {
        scoreCardContainerNode.position.y = 200
        scoreCardNode.isHidden = false
        setCurrentPlayer(index: 0)
        
        let moveIn = SKAction.move(to: .zero, duration: 0.5)
        moveIn.timingFunction = { time in
            time * (2 - time)
        }
        
        scoreCardContainerNode.run(moveIn)
    }
    
    public func cutTo(color: UIColor, callback: @escaping () -> ()) {
        let rectangleLocations: [CGFloat] = [-512, -318, -122, 0, 194, 338, 512]
        let waitTimes: [TimeInterval] = [0.06,0.1,0.04,0.08,0.0,0.05,0.09]
        
        let maxWaitTime = 0.1
        let duration = 0.3
        
        let containerNode = SKNode()
        addChild(containerNode)
        containerNode.zRotation = self.rotationNode.zRotation + .pi / 2.0
        containerNode.zPosition = 50
        
        for (index,location) in rectangleLocations.enumerated() {
            let waitTime = waitTimes[index]
            let rectangle = SKShapeNode(rectOf: CGSize(width: 200, height: 1280))
            rectangle.position.x = location
            rectangle.fillColor = color
            rectangle.strokeColor = color
            rectangle.xScale = 0
            containerNode.addChild(rectangle)
            
            let expand = SKAction.scaleX(to: 1.0, duration: duration)
            expand.timingFunction = { x in
                return pow(x, 1.5)
            }
            
            let action = SKAction.sequence([
                SKAction.wait(forDuration: waitTime),
                expand
                ])
            rectangle.run(action)
        }
        
        containerNode.run(SKAction.sequence([
            SKAction.wait(forDuration: duration + maxWaitTime),
            SKAction.run({
                self.backgroundColor = color
                self.gameNode.removeFromParent()
                containerNode.removeFromParent()
                callback()
            })
            ]))
    }
}

public class SpheroPongViewController: SceneViewController {
    let pongScene: SpheroPongScene
    
    let accessibilityContainerView = UIView()
    
    let playAreaAccessibilityView = UIView()
    let scoreboardAccessibilityView = UIView()
    let bottomMessageAccessibilityView = UIView()
    
    var scoreboardVisibleConstraint: NSLayoutConstraint? = nil
    var bottomMessageVisibleConstraint: NSLayoutConstraint? = nil
    
    let stoppedPlayAreaDescription = NSLocalizedString("SpheroPongScene_StoppedPlayAreaDescription", value: "A Sphero with lines moving across the screen behind it", comment: "VoiceOver description of Sphero pong game.")
    let rollingPlayAreaDescripition = NSLocalizedString("SpheroPongScene_RollingPlayAreaDescription", value: "A Sphero moving quickly with lines flying across the screen behind it", comment: "VoiceOver description of Sphero pong game in action.")
    
    let scoreboardMessageFormat = NSLocalizedString("sd:SpheroPong_ScoreboardAccessibilityMessage", value: "A scoreboard showing Player 1 with %1$d points versus Player 2 with %2$d points", comment: "VoiceOver description of a scoreboard in Sphero pong. %1$d and %2$d are replaced with Player 1's and Player 2's scores respectively. The words \"points\" are replaced with \"point\" when a player has exactly 1 point.")
    
    public init() {
        pongScene = SpheroPongScene()
        super.init(scene: pongScene)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        pongScene = SpheroPongScene()
        super.init(coder: aDecoder)
        self.scene = pongScene
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        pongScene.backgroundColor = view.backgroundColor ?? #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        pongScene.safeAreaContainer = self
        
        accessibilityContainerView.addSubview(playAreaAccessibilityView)
        accessibilityContainerView.addSubview(scoreboardAccessibilityView)
        accessibilityContainerView.addSubview(bottomMessageAccessibilityView)
        
        if let toyConnectionView = toyConnectionView {
            view.insertSubview(accessibilityContainerView, belowSubview: toyConnectionView)
        }
        else {
            view.addSubview(accessibilityContainerView)
        }
        
        accessibilityContainerView.translatesAutoresizingMaskIntoConstraints = false
        accessibilityContainerView.isAccessibilityElement = false
        accessibilityContainerView.accessibilityElementsHidden = overlayView != nil
        
        playAreaAccessibilityView.translatesAutoresizingMaskIntoConstraints = false
        playAreaAccessibilityView.isAccessibilityElement = true
        playAreaAccessibilityView.accessibilityLabel = stoppedPlayAreaDescription
        
        scoreboardAccessibilityView.translatesAutoresizingMaskIntoConstraints = false
        scoreboardAccessibilityView.isAccessibilityElement = true
        scoreboardAccessibilityView.accessibilityLabel = String(format: scoreboardMessageFormat, 0, 0)
        
        bottomMessageAccessibilityView.translatesAutoresizingMaskIntoConstraints = false
        bottomMessageAccessibilityView.isAccessibilityElement = true
        bottomMessageAccessibilityView.accessibilityTraits = UIAccessibilityTraitStaticText
        
        let scoreboardGoneConstraint = scoreboardAccessibilityView.heightAnchor.constraint(equalToConstant: 0.0)
        scoreboardGoneConstraint.priority = 999
        scoreboardVisibleConstraint = scoreboardAccessibilityView.heightAnchor.constraint(equalToConstant: 170.0)
        
        let bottomMessageGoneConstraint = bottomMessageAccessibilityView.heightAnchor.constraint(equalToConstant: 0.0)
        bottomMessageGoneConstraint.priority = 999
        bottomMessageVisibleConstraint = bottomMessageAccessibilityView.heightAnchor.constraint(equalTo: liveViewSafeAreaGuide.heightAnchor, multiplier: 0.18)
        
        NSLayoutConstraint.activate([
            accessibilityContainerView.topAnchor.constraint(equalTo: liveViewSafeAreaGuide.topAnchor),
            accessibilityContainerView.bottomAnchor.constraint(equalTo: liveViewSafeAreaGuide.bottomAnchor),
            accessibilityContainerView.leadingAnchor.constraint(equalTo: liveViewSafeAreaGuide.leadingAnchor),
            accessibilityContainerView.trailingAnchor.constraint(equalTo: liveViewSafeAreaGuide.trailingAnchor),
        
            scoreboardAccessibilityView.centerXAnchor.constraint(equalTo: accessibilityContainerView.centerXAnchor),
            scoreboardAccessibilityView.widthAnchor.constraint(equalToConstant: scoreCardSize.width),
            scoreboardAccessibilityView.topAnchor.constraint(equalTo: accessibilityContainerView.topAnchor),
            
            scoreboardAccessibilityView.bottomAnchor.constraint(equalTo: playAreaAccessibilityView.topAnchor),
            
            playAreaAccessibilityView.leadingAnchor.constraint(equalTo: accessibilityContainerView.leadingAnchor),
            playAreaAccessibilityView.trailingAnchor.constraint(equalTo: accessibilityContainerView.trailingAnchor),
            
            playAreaAccessibilityView.bottomAnchor.constraint(equalTo: bottomMessageAccessibilityView.topAnchor),
            
            bottomMessageAccessibilityView.leadingAnchor.constraint(equalTo: accessibilityContainerView.leadingAnchor),
            bottomMessageAccessibilityView.trailingAnchor.constraint(equalTo: accessibilityContainerView.trailingAnchor),
            
            bottomMessageAccessibilityView.bottomAnchor.constraint(equalTo: accessibilityContainerView.bottomAnchor),
            
            scoreboardGoneConstraint,
            bottomMessageGoneConstraint
        ])
    }
    
    public override func didReceiveRollMessage(heading: Double, speed: Double) {
        let direction = CGFloat(heading * .pi / 180.0)
        let speed = CGFloat(speed.clamp(lowerBound: 0.0, upperBound: 255.0))
        
        if speed != 0.0 {
            playAreaAccessibilityView.accessibilityLabel = rollingPlayAreaDescripition
        }
        
        pongScene.onRoll(speed: speed, direction: direction)
    }
    
    public override func onReceive(message: PlaygroundValue) {
        super.onReceive(message: message)
        
        guard let dict = message.dictValue(),
            let typeId = dict[MessageKeys.type]?.intValue()
            else { return }
        
        if typeId == MessageTypeId.startPong.rawValue {
            if let leftPaddleColor = dict[MessageKeys.pongLeftPaddleColor]?.colorValue() {
                pongScene.setFace(color: leftPaddleColor, forPlayer:0)
            }
            
            if let rightPaddleColor = dict[MessageKeys.pongRightPaddleColor]?.colorValue() {
                pongScene.setFace(color: rightPaddleColor, forPlayer:1)
            }
            
            pongScene.start()
            self.scoreboardVisibleConstraint?.isActive = true
        }
        
        if typeId == MessageTypeId.pointsScored.rawValue,
            let playerNumber = dict[MessageKeys.playerNumber]?.intValue(),
            let points = dict[MessageKeys.points]?.intValue() {
            
            let playerIndex = playerNumber - 1
            
            pongScene.player(index: playerIndex, scored: points)
            
            
            // Scoring animation is read out by the speech synthesizer and we don't want VoiceOver to talk over that,
            // so remove the accessibility label. (it gets re-added when sphero rolls)
            playAreaAccessibilityView.accessibilityLabel = nil
            scoreboardVisibleConstraint?.isActive = false
            
            updateScoreboardAccessibilityMessage()
        }
        
        if typeId == MessageTypeId.pongEnded.rawValue,
            let playerNumber = dict[MessageKeys.playerNumber]?.intValue() {
            
            playAreaAccessibilityView.accessibilityLabel = NSLocalizedString("SpheroPong_TrophyImageDescription", value: "A happy Sphero sits inside a trophy with stars shooting from behind it", comment: "VoiceOver description of the winning image in sphero pong")
            scoreboardVisibleConstraint?.isActive = false
            bottomMessageVisibleConstraint?.isActive = true
            bottomMessageAccessibilityView.accessibilityLabel = String(format: resultsLabelTextFormat, playerNumber)
            
            pongScene.showWinner(playerIndex: playerNumber - 1)
        }
        
        if typeId == MessageTypeId.pongCurrentPlayerChanged.rawValue,
            let playerNumber = dict[MessageKeys.playerNumber]?.intValue() {
            
            pongScene.setCurrentPlayer(index: playerNumber - 1)
        }
        
        if typeId == MessageTypeId.showTimer.rawValue,
            let time = dict[MessageKeys.time]?.doubleValue() {
            
            pongScene.showTimer(for: time)
            
            playAreaAccessibilityView.accessibilityLabel = NSLocalizedString("SpheroPong_TimerAccessibilityDescription", value: "A stopwatch counting down", comment: "VoiceOver description of a stopwatch that counts down in between rounds of SpheroPong")
        }
    }
    
    private func updateScoreboardAccessibilityMessage() {
        scoreboardAccessibilityView.accessibilityLabel = String(format: scoreboardMessageFormat, pongScene.getScore(forPlayer: 0), pongScene.getScore(forPlayer: 1))
    }
    
    public override func didReceiveCollision(data: CollisionData) {
        super.didReceiveCollision(data: data)
        
        pongScene.showCollision()
    }
    
    public override func liveViewMessageConnectionOpened() {
        super.liveViewMessageConnectionOpened()
        
        pongScene.reset()
        
        accessibilityContainerView.accessibilityElementsHidden = false
    }
    
    public override func liveViewMessageConnectionClosed() {
        super.liveViewMessageConnectionClosed()
        
        pongScene.setSpeed(0.0, direction: 0.0)
        
        pongScene.hideTimer()
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Scoreboard is moved down to make room for BT connection when safe area is too narrow to have them next to eachother
        scoreboardVisibleConstraint?.constant = self.liveViewSafeAreaGuide.layoutFrame.width < scoreCardDisplacementSceneWidthThreshold ? 205.0 : 130.0
    }
}

extension SKAction {
    
    public static func squishWithHeight(_ height: CGFloat, toFactor factor: CGFloat, up: Bool, duration: TimeInterval) -> SKAction {
        let directionSign: CGFloat = up ? 1.0 : -1.0
        let squishDisplacement: CGFloat = directionSign * (1.0 - factor) * height / 2.0
        
        let squish = SKAction.sequence([
            .group([
                .scaleY(to: factor, duration: duration / 2.0),
                .move(by: CGVector(dx: 0, dy:squishDisplacement), duration: duration / 2.0)
                ]),
            .group([
                .scaleY(to: 1.0, duration: duration / 2.0),
                .move(by: CGVector(dx: 0, dy:-squishDisplacement), duration: duration / 2.0)
                ])
            ])
        
        return squish
    }
}
