//
//  Sound.swift
//  PlaygroundContent
//
//  Created by Anthony Blackman on 2017-04-20.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation
import AVFoundation

public class Sound {
    
    private let name: String
    private var player: AVAudioPlayer?
    private let volume: Float
    
    private static let queue = DispatchQueue(label: "com.sphero.sound.queue")
    
    public init(_ name: String, ext: String = "mp3", volume: Float = 1.0) {
        self.name = name
        self.volume = volume
        
        Sound.queue.async {
            guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return }
            
            self.player = try? AVAudioPlayer(contentsOf: url)
            self.player?.prepareToPlay()
            // Takes a while to load the first time.
            // Play it inaudibly.
            self.player?.volume = 0.0001
            self.player?.play()

        }
    }
    
    func play() {
        Sound.queue.async {
            guard let player = self.player else { return }
            if player.isPlaying {
                player.stop()
            }
            player.currentTime = 0.0
            player.volume = self.volume
            player.prepareToPlay()
            player.play()
        }
    }
}
