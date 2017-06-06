//
//  VolleyLiveViewController.swift
//  spheroArcade
//
//  Created by Jeff Payan on 2017-03-31.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit

@objc(VolleyLineView)
public class VolleyLineView: UIView {

    public var endLineHeight: CGFloat = 0.0

    private var dashedLine: CAShapeLayer?

    public override func layoutSubviews() {
        dashedLine?.removeFromSuperlayer()
        dashedLine = nil
        
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        let lineFrame = bounds
        let radius = frame.size.width * 0.5
        linePath.move(to: CGPoint(x: lineFrame.minX, y: lineFrame.maxY))
        linePath.addLine(to: CGPoint(x: lineFrame.minX, y: lineFrame.minY + radius))
        linePath.addArc(withCenter: CGPoint(x: lineFrame.minX + radius, y: lineFrame.minY + radius),
                        radius: radius, startAngle: -.pi, endAngle: 0.0, clockwise: true)
        linePath.addLine(to: CGPoint(x: lineFrame.maxX, y: lineFrame.minY + endLineHeight))
        line.path = linePath.cgPath
        line.strokeColor = UIColor.white.cgColor
        line.fillColor = UIColor.clear.cgColor
        line.lineWidth = 3.5
        line.lineJoin = kCALineJoinRound
        line.lineDashPattern = [10, 10]
        layer.addSublayer(line)
        dashedLine = line
    }
    
}

@objc(BackandForthLiveViewController)
public class BackandForthLiveViewController: SpheroPongViewController {
    
    @IBOutlet weak var dotStartView: UIView!
    @IBOutlet weak var dottedLineView: VolleyLineView!
    @IBOutlet weak var arrowImageView: UIImageView!

    @IBOutlet weak var topRulerConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomRulerConstraint: NSLayoutConstraint!
    @IBOutlet weak var endLineConstraint: NSLayoutConstraint!
    @IBOutlet weak var topRulerImageView: UIImageView!
    @IBOutlet weak var bottomRulerImageView: UIImageView!
    @IBOutlet weak var topShoesImageView: UIImageView!
    @IBOutlet weak var bottomShoesImageView: UIImageView!
    @IBOutlet weak var lineAndSpheroAccessibilityContainer: UIView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        arrowImageView.transform = CGAffineTransform(rotationAngle: 0.5 * .pi)
        
        topRulerImageView.accessibilityLabel = NSLocalizedString("volley.topRuler.accessibility", value: "A piece of Sphero maze tape, indicating the top bounds of Sphero Pong.", comment: "volley setup image accessibility, image is a piece of tape used to mark where player 2 should stand.")
        bottomRulerImageView.accessibilityLabel = NSLocalizedString("volley.bottomRuler.accessibility", value: "A piece of Sphero maze tape, indicating the bottom bounds of Sphero Pong.", comment: "volley setup image accessibility, image is a piece of tape used to mark where player 1 should stand.")
        
        topShoesImageView.accessibilityLabel = NSLocalizedString("volley.topShoes.accessibility", value: "Player 2's red shoes standing behind the top piece of maze tape.", comment: "real world setup image accessibility, image is a pair of red shoes.")
        bottomShoesImageView.accessibilityLabel = NSLocalizedString("volley.bottomShoes.accessibility", value: "Player 1's blue shoes standing behind the bottom piece of maze tape.", comment: "real world setup image accessibility, image is a pair of blue shoes.")
        
        lineAndSpheroAccessibilityContainer.accessibilityLabel = NSLocalizedString("volley.accessibilityContainer.accessibilityLabel", value: "Sphero is rolling from Player 1's shoes to Player 2's shoes, turning around and coming back towards Player 1.", comment: "back and forth accessibility, describing sp")
    }
    
    public override func updateViewConstraints() {
        let offset: CGFloat = isVerticallyCompact() ? 60.0 : 140.0
        topRulerConstraint.constant = offset
        bottomRulerConstraint.constant = offset
        
        let height: CGFloat = isVerticallyCompact() ? 40.0 : 60.0
        endLineConstraint.constant = height
        dottedLineView.endLineHeight = height
        
        super.updateViewConstraints()
    }
    
    public override func didReceiveSetMainLedMessage(color: UIColor) {
        super.didReceiveSetMainLedMessage(color: color)
        
        pongScene.backgroundColor = color
    }
    
    public override func didReceiveRollMessage(heading: Double, speed: Double) {
        // In actual sphero pong, current player is updated by the SpheroPongGame via playground messages.
        // In back and forth the game isn't run, so determine current player based on angle.
        pongScene.setCurrentPlayer(index: abs(heading.canonizedAngle()) > 90.0 ? 0 : 1)
    
        super.didReceiveRollMessage(heading: heading, speed: speed)
    }
    
    public override func liveViewMessageConnectionOpened() {
        super.liveViewMessageConnectionOpened()
        
        if let backgroundColor = view.backgroundColor {
            pongScene.backgroundColor = backgroundColor
        }
    }
}
