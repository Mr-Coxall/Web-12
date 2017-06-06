//#-hidden-code
//
//  Contents.swift
//  spheroArcade
//
//  Created by Jordan Hesse on 2017-03-17.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//
import Foundation
import PlaygroundSupport
import UIKit

var initialBallSpeed = 300
var maximumBallSpeed = 800
var ballSpeedIncrement = 20

var ballColor: UIColor = .white
var leftPaddleColor: UIColor = .white
var rightPaddleColor: UIColor = .white
var backgroundColor: UIColor = .white

class PongLiveViewDelegate: SpheroPlaygroundRemoteLiveViewProxyDelegate {
    public func receive(_ message: PlaygroundValue) {
        guard let dict = message.dictValue(),
            let typeId = dict[MessageKeys.type]?.intValue(),
            typeId == MessageTypeId.pongEnded.rawValue
            else { return }
        
        if PlaygroundPage.current.assessmentStatus == nil {
            PlaygroundPage.current.assessmentStatus = .pass(message: NSLocalizedString("originalPong.success.pageComplete", value: "Wasn't that fun? Tap the \"PLAY AGAIN\" button, or move on to the [next page](@next).", comment: "[] indicator that the text will be hyper linked, @(next) is URL link that is applied to [next page], localize 'Wasn't that fun? Tap the \"PLAY AGAIN\" button, or move on to the next page'"))
        }
    }

    public func remoteLiveViewProxyConnectionClosed(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy) {
        
    }
}

let delegate = PongLiveViewDelegate()

private func playPong() {
    var pongConfigDict = [String:PlaygroundValue]()
    
    pongConfigDict[MessageKeys.type] = MessageTypeId.startPong.playgroundValue()
    
    pongConfigDict[MessageKeys.initialBallSpeed] = .floatingPoint(Double(initialBallSpeed))
    pongConfigDict[MessageKeys.maximumBallSpeed] = .floatingPoint(Double(maximumBallSpeed))
    pongConfigDict[MessageKeys.ballSpeedIncrement] = .floatingPoint(Double(ballSpeedIncrement))
    
    pongConfigDict[MessageKeys.pongBallColor] = PlaygroundValue(color: ballColor)
    pongConfigDict[MessageKeys.pongLeftPaddleColor] = PlaygroundValue(color: leftPaddleColor)
    pongConfigDict[MessageKeys.pongRightPaddleColor] = PlaygroundValue(color: rightPaddleColor)
    pongConfigDict[MessageKeys.pongBackgroundColor] = PlaygroundValue(color: backgroundColor)
    
    PlaygroundHelpers.sendMessageToLiveView(.dictionary(pongConfigDict))
}

PlaygroundPage.current.needsIndefiniteExecution = true
PlaygroundHelpers.setLiveViewProxyDelegate(delegate)
//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
 **Goal:** Play Pong to see how the game works.
 
 Start this chapter by playing the original Pong game! Tap "Run My Code", then grab a paddle to play against the computer, or grab a friend to play against each other. You can even change some variables to customize the game.
 */

// Customize colors.
ballColor = /*#-editable-code*/#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)/*#-end-editable-code*/
leftPaddleColor = /*#-editable-code*/#colorLiteral(red: 0.2916591763, green: 0.4149196744, blue: 0.4695840478, alpha: 1)/*#-end-editable-code*/
rightPaddleColor = /*#-editable-code*/#colorLiteral(red: 0.2916591763, green: 0.4149196744, blue: 0.4695840478, alpha: 1)/*#-end-editable-code*/
backgroundColor = /*#-editable-code*/#colorLiteral(red: 0.524340868, green: 0.6308438182, blue: 0.677141428, alpha: 1)/*#-end-editable-code*/

// Customize difficulty.
initialBallSpeed = /*#-editable-code*/300/*#-end-editable-code*/
maximumBallSpeed = /*#-editable-code*/800/*#-end-editable-code*/
ballSpeedIncrement = /*#-editable-code*/20/*#-end-editable-code*/

playPong()
//#-end-hidden-code
