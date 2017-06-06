//
//  ToyDisplayScene.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-09.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import AVFoundation
import SpriteKit
import PlaygroundSupport

public enum CameraMode {
    case FollowToy
    case Zoom
}

public protocol SafeFrameContainer: class {
    var liveViewSafeAreaFrame: CGRect { get }
}

public class ToyDisplayScene: SKScene {
    
    public let toyNode: SKNode
    public let ledNode: SKShapeNode
    private let toyFaceNode: SKNode
    private let toyFaceRotationNode: SKNode
    
    public let toyBody: SKPhysicsBody
    
    public weak var safeFrameContainer: SafeFrameContainer?
    
    private var desiredToySpeed: CGFloat = 0.0
    private var desiredToyDirection: CGFloat = 0.0
    private var currentToyDirection: CGFloat = 0.0
    
    private var maxToyTurnSpeed: CGFloat = 0.3
    private var maxToyAcceleration: CGFloat = 10.0
    
    private var toySpeedMultiplier: CGFloat = 2.0
    
    private var toyPathDashPatternLength: CGFloat = 20.0
    
    private var pathNode: SKNode?
    
    private let maxToyPathPointCount = 250
    private var toyPathPoints: [CGPoint] = []
    
    private var cameraNode: SmoothPanningCameraNode
    
    private var maxToyPositionX: CGFloat = 0.0
    private var maxToyPositionY: CGFloat = 0.0
    private var minToyPositionX: CGFloat = 0.0
    private var minToyPositionY: CGFloat = 0.0
    
    private var collisionNode: SKShapeNode?
    
    public var cameraMode = CameraMode.Zoom
    
    private var originDotNode: SKShapeNode
    
    private var faceAngle: CGFloat = 0.0
    
    private var extraNodes = [SKSpriteNode]()
    
    private let rotationNode = SKSpriteNode(imageNamed: "rotation")
    
    public let speaker = AccessibilitySpeechQueue()
    
    public override init(size: CGSize) {
        
        let toyShapeNode = SKSpriteNode(imageNamed: "spheroSimulatorBody")
        toyShapeNode.isAccessibilityElement = true
        toyShapeNode.accessibilityHint = NSLocalizedString("SpheroSimulator_AccessibilitySpheroHint", value: "Sphero", comment: "Accessibility hint for Sphero image in Sphero simulator.")
        toyShapeNode.accessibilityTraits = UIAccessibilityTraitImage
        
        toyNode = toyShapeNode
        
        ledNode = SKShapeNode(circleOfRadius: 0.2)
        ledNode.alpha = 0.5
        
        toyBody = SKPhysicsBody()
        toyNode.physicsBody = toyBody
        toyBody.affectedByGravity = false
        toyBody.linearDamping = 0.0
        
        toyFaceRotationNode = SKNode()
        toyNode.addChild(toyFaceRotationNode)
        
        toyFaceNode = SKSpriteNode(imageNamed: "spheroFace")
        toyFaceNode.xScale = 0.3
        toyFaceNode.yScale = 0.3
        toyFaceRotationNode.addChild(toyFaceNode)
        
        cameraNode = SmoothPanningCameraNode()
        
        originDotNode = SKShapeNode(circleOfRadius: 9.0)
        
        super.init(size: size)
        
        addChild(originDotNode)
        
        addChild(toyNode)
        toyNode.addChild(ledNode)
        
        // Ensure that the led node is on top of the toy.
        toyNode.zPosition = 0.0
        ledNode.zPosition = 1.0
        
        self.physicsWorld.gravity = .zero
        self.scaleMode = .resizeFill
        
        cameraNode.position = originDotNode.position
        self.camera = cameraNode
        
        addChild(cameraNode)
        
        rotationNode.zPosition = -1
        
        reset()
    }
    
    public override convenience init() {
        let screenSize = UIScreen.main.bounds
        
        let size = max(screenSize.width, screenSize.height)
        
        self.init(size: CGSize(width:size, height: size))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func reset() {
        // Put the toy in the middle of the scene.
        toyNode.position.x = 0.0
        toyNode.position.y = 0.0
        
        stopToy()
        
        desiredToyDirection = toSceneHeading(toyHeading: 0.0)
        currentToyDirection = toSceneHeading(toyHeading: 0.0)
        
        setColor(.clear)
        
        toyPathPoints = [toyNode.position]
        
        pathNode?.removeFromParent()
        
        if rotationNode.parent != nil {
            rotationNode.removeFromParent()
        }
        
        updateSceneBounds()
        
        cameraNode.cut()
        
        collisionNode?.removeFromParent()
        collisionNode = nil
    }
    
    private func stopToy() {
        desiredToySpeed = 0.0
        toyBody.velocity = .zero
    }
    
    public func setColor(_ color: UIColor) {
        ledNode.fillColor = color
        
        ledNode.strokeColor = color
        
        ledNode.glowWidth = 40.0
    }
    
    public func roll(heading: Double, speed: Double) {
        desiredToySpeed = CGFloat(speed) * toySpeedMultiplier
        desiredToyDirection = toSceneHeading(toyHeading: heading)
        
        let message: String
        
        if speed == 0.0 {
            message = NSLocalizedString("SpheroSimulator_StopActionDescription", value: "Sphero stops", comment: "VoiceOver description for Sphero stopping")
        } else {
            
            let angleDescription = heading.angleDescription()
            let actionDescription =
                speed < 50.0 ? NSLocalizedString("SpheroSimulator_RollSlowlyActionDescription", value: "rolls slowly", comment: "VoiceOver description for Sphero rolling slowly") :
                speed < 150.0 ? NSLocalizedString("SpheroSimulator_RollActionDescription", value: "rolls", comment: "VoiceOver description for Sphero rolling") :
                NSLocalizedString("SpheroSimulator_RollQuicklyActionDescription", value: "rolls quickly", comment: "VoiceOver description for Sphero rolling quickly")
            
            message = String(format: NSLocalizedString("SpheroSimulator_SpheroActionMessage", value: "Sphero %1$@ heading %2$@", comment: "VoiceOver description for Sphero action. %1$@ is replaced with an action and %2$@ is replaced with a direction (e.g. Sphero rolls quickly heading forward-left)"), actionDescription, angleDescription)
        }
        
        speaker.speak(message)
    }
    
    public func showCollision(data: CollisionData) {
        stopToy()
        
        if collisionNode == nil {
            let newCollisionNode = SKShapeNode(rectOf: CGSize(width: 3.0, height: 100.0), cornerRadius: 1.5)
            newCollisionNode.fillColor = .black
            newCollisionNode.strokeColor = .black
            // On top of path line, under the toy.
            newCollisionNode.zPosition = 0.5
            
            addChild(newCollisionNode)
            collisionNode = newCollisionNode
        }
        
        let impactAngle = toSceneAngle(toyAngle: data.impactAngle)
        let impactHeading = impactAngle + desiredToyDirection
        
        let collisionNodeOffsetDirection = impactHeading + .pi
        
        collisionNode?.position.x = toyNode.position.x + 38.0*cos(collisionNodeOffsetDirection)
        collisionNode?.position.y = toyNode.position.y + 38.0*sin(collisionNodeOffsetDirection)
        
        collisionNode?.zRotation = impactHeading
        
        let message = NSLocalizedString("SpheroSimulator_CollisionMessage", value: "Sphero detected a collision", comment: "VoiceOver description of Sphero detecting a collision.")
        speaker.speak(message)
    }
    
    public func showRotation() {
        rotationNode.position = toyNode.position
        // Rotation image is not centered.
        rotationNode.position.x += 2.0
        
        if rotationNode.parent == nil {
            addChild(rotationNode)
        }
    }
    
    public override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        updateToy()
        
        updatePath()
        
        panCamera()
    }
    
    private func updateToy() {
        var angleDifference = (desiredToyDirection - currentToyDirection).truncatingRemainder(dividingBy: 2.0 * .pi)
        let pi = CGFloat.pi
        if angleDifference > pi {
            angleDifference -= 2.0 * pi
        } else if angleDifference <= -pi {
            angleDifference += 2.0 * pi
        }
        
        let angleChangeMagnitude = min(maxToyTurnSpeed, abs(angleDifference))
        let angleChange = copysign(angleChangeMagnitude, angleDifference)
        currentToyDirection += angleChange
        
        let desiredSpeedX = cos(desiredToyDirection) * desiredToySpeed
        let desiredSpeedY = sin(desiredToyDirection) * desiredToySpeed
        
        let speedDifferenceX = desiredSpeedX - toyBody.velocity.dx
        let speedDifferenceY = desiredSpeedY - toyBody.velocity.dy
        
        let speedDifference = hypot(speedDifferenceX, speedDifferenceY)
        let speedChangeMagnitude = min(maxToyAcceleration, speedDifference)
        let speedChangeDirection = atan2(speedDifferenceY, speedDifferenceX)
        
        toyBody.velocity.dx += cos(speedChangeDirection) * speedChangeMagnitude
        toyBody.velocity.dy += sin(speedChangeDirection) * speedChangeMagnitude
        
        // The image is pointed down, but zRotation=0 is pointed right.
        // Rotate by an extra pi/2
        toyNode.zRotation = currentToyDirection + pi / 2.0
        // Un-rotate the face so the logo is upright.
        toyFaceNode.zRotation = -toyNode.zRotation + cameraNode.zRotation
        
        maxToyPositionX = max(maxToyPositionX, toyNode.position.x)
        maxToyPositionY = max(maxToyPositionY, toyNode.position.y)
        minToyPositionX = min(minToyPositionX, toyNode.position.x)
        minToyPositionY = min(minToyPositionY, toyNode.position.y)
        
        let actualToySpeed = hypot(toyBody.velocity.dx, toyBody.velocity.dy)
        
        faceAngle += actualToySpeed * 0.00125
        if faceAngle > 2.0 * pi {
            faceAngle -= 2.0 * pi
        }
        
        // Skip part of the face being behind the ball.
        if faceAngle > 0.7 * pi && faceAngle < 1.5 * pi {
            faceAngle = 1.5 * pi
        }
        
        toyFaceRotationNode.yScale = max(0.0, cos(faceAngle))
        toyFaceRotationNode.position.y = -sin(faceAngle) * 25.0
    }
    
    private func updatePath() {
        
        let lastToyPathPoint = toyPathPoints.last ?? .zero
        
        let pathDistanceX = toyNode.position.x - lastToyPathPoint.x
        let pathDistanceY = toyNode.position.y - lastToyPathPoint.y
        let pathDistance = hypot(pathDistanceX, pathDistanceY)
        
        if pathDistance > toyPathDashPatternLength {
            pathNode?.removeFromParent()
            
            // Scale the movement so that the new point is exactly toyPathDashPatternLength away.
            // This makes it so that when we remove a point, exactly toyPathDashPatternLength is removed, so that the dashes don't move.
            
            let scale = toyPathDashPatternLength / pathDistance
            
            let newPointX = lastToyPathPoint.x + pathDistanceX * scale
            let newPointY = lastToyPathPoint.y + pathDistanceY * scale
            
            toyPathPoints.append(CGPoint(x: newPointX, y: newPointY))
            
            if toyPathPoints.count > maxToyPathPointCount {
                toyPathPoints.remove(at: 0)
                
                updateSceneBounds()
            }
            
            let toyPath = UIBezierPath()
            
            toyPath.move(to: toyPathPoints.first!)
            
            for point in toyPathPoints[1 ..< toyPathPoints.count] {
                toyPath.addLine(to: point)
            }
            
            let dashed = toyPath.cgPath.copy(dashingWithPhase: 2, lengths: [toyPathDashPatternLength/2.0, toyPathDashPatternLength/2.0])
            
            let node = SKShapeNode(path: dashed)
            node.lineWidth = 3.5
            // Ensure that the path is behind the toy
            node.zPosition = -1.0
            addChild(node)
            
            pathNode = node
        }
    }
    
    private func updateSceneBounds() {
        maxToyPositionX = toyNode.position.x
        minToyPositionX = toyNode.position.x
        maxToyPositionY = toyNode.position.y
        minToyPositionY = toyNode.position.y
        
        for point in toyPathPoints {
            maxToyPositionX = max(maxToyPositionX, point.x)
            minToyPositionX = min(minToyPositionX, point.x)
            maxToyPositionY = max(maxToyPositionY, point.y)
            minToyPositionY = min(minToyPositionY, point.y)
        }
        
        for node in extraNodes {
            maxToyPositionX = max(maxToyPositionX, node.position.x + node.size.width / 2.0)
            minToyPositionX = min(minToyPositionX, node.position.x - node.size.width / 2.0)
            maxToyPositionY = max(maxToyPositionY, node.position.y + node.size.height / 2.0)
            minToyPositionY = min(minToyPositionY, node.position.y - node.size.height / 2.0)
        }
    }
    
    private func panCamera() {
        
        switch cameraMode {
        case .Zoom:
            let padding: CGFloat = 75.0
            
            let maxX = maxToyPositionX + padding
            let minX = minToyPositionX - padding
            
            let maxY = maxToyPositionY + padding
            let minY = minToyPositionY - padding
            
            let isLandscape = size.width > size.height
            
            let sceneFrame = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
            let cameraFrame: CGRect
            
            if let safeFrameContainer = safeFrameContainer {
                let frame = safeFrameContainer.liveViewSafeAreaFrame
                
                // swap y orientation, put center at origin
                cameraFrame = CGRect(
                    x: frame.minX - size.width / 2.0,
                    y: size.height / 2.0 - frame.maxY,
                    width: frame.width,
                    height: frame.height
                )
            } else {
                cameraFrame = CGRect(origin: .zero, size: self.size)
            }
            
            let toyPadding: CGFloat = padding + 60
            let toyRect = CGRect(x: toyNode.position.x - toyPadding, y: toyNode.position.y - toyPadding, width: 2.0 * toyPadding, height: 2.0 * toyPadding)
            
            cameraNode.pan(showing: sceneFrame, withMainFocus: toyRect, in: cameraFrame, landscape: isLandscape)
            
        case .FollowToy:
            cameraNode.panTowards(desiredPosition: toyNode.position, desiredScale: 1.0)
        }
    }
    
    // Converts a heading in clockwise degrees with upward origin
    // to counterclockwise radians with rightward origin.
    private func toSceneHeading(toyHeading: Double) -> CGFloat {
        return CGFloat(90.0 - toyHeading) * .pi / 180.0
    }
    
    // Converts an angle from clockwise degrees to counterclockwise radians
    private func toSceneAngle(toyAngle: Double) -> CGFloat {
        return CGFloat(-toyAngle) * .pi / 180.0
    }
    
    public override func didChangeSize(_ oldSize: CGSize) {
        cameraNode.cut()
    }
    
    public func setOriginDotColor(_ color: UIColor) {
        originDotNode.fillColor = color
        originDotNode.strokeColor = color
    }
    
    public func addExtraNode(_ node: SKSpriteNode) {
        addChild(node)
        extraNodes.append(node)
        updateSceneBounds()
        cameraNode.cut()
    }
    
}
