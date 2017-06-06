//
//  Utils.swift
//  spheroArcade
//
//  Created by Jeff Payan on 2017-03-20.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit

extension UIViewController {
    
    public static func instantiateFromStoryboard<T>() -> T {
        let bundle = Bundle(for: T.self as! AnyClass)
        let storyboard = UIStoryboard(name: "SpheroArcade", bundle: bundle)
        let identifier = String(describing: self)
        
        return storyboard.instantiateViewController(withIdentifier: identifier) as! T
    }
    
}

extension UIFont {
    
    public static let arcadeFontName: String = {
        let fontUrl = Bundle.main.url(forResource: "slkscr", withExtension: "ttf")!
        CTFontManagerRegisterFontsForURL(fontUrl as CFURL, CTFontManagerScope.process, nil)
        return "Silkscreen"
    }()
    
    public class func arcadeFont(ofSize fontSize: CGFloat) -> UIFont {
        return UIFont(name: arcadeFontName, size: 25.0)!
    }
    
}


private let angleDescriptions: [(Double,String)] = [
    (0.0,    NSLocalizedString("SpheroSimulator_AngleDescription_Forward",     value: "Forward",      comment: "VoiceOver description for Sphero heading Forward")),
    (45.0,   NSLocalizedString("SpheroSimulator_AngleDescription_ForwardRight", value: "Forward Right", comment: "VoiceOver description for Sphero heading Forward Right")),
    (90.0,   NSLocalizedString("SpheroSimulator_AngleDescription_Right",      value: "Right",       comment: "VoiceOver description for Sphero heading Right")),
    (135.0,  NSLocalizedString("SpheroSimulator_AngleDescription_BackwardRight", value: "Backward Right", comment: "VoiceOver description for Sphero heading Backward Right")),
    (180.0,  NSLocalizedString("SpheroSimulator_AngleDescription_Backward",     value: "Backward",      comment: "VoiceOver description for Sphero heading Backward")),
    (-135.0, NSLocalizedString("SpheroSimulator_AngleDescription_BackwardLeft", value: "Backward Left", comment: "VoiceOver description for Sphero heading Backward Left")),
    (-90.0,  NSLocalizedString("SpheroSimulator_AngleDescription_Left",      value: "Left",       comment: "VoiceOver description for Sphero heading Left")),
    (-45.0,  NSLocalizedString("SpheroSimulator_AngleDescription_ForwardLeft", value: "Forward Left", comment: "VoiceOver description for Sphero heading Forward Left"))
]

extension Double {

    public func angleDescription() -> String {
        var bestDescription = ""
        var minAngleDistance = 360.0
        
        for (angle, description) in angleDescriptions {
            let distance = abs((angle - self).canonizedAngle())
            
            if distance < minAngleDistance {
                minAngleDistance = distance
                bestDescription = description
            }
        }
        
        return bestDescription
    }
    
}
