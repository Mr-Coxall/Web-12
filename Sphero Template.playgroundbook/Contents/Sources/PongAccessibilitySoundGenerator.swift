//
//  PongAccessibilitySoundGenerator
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-04-17.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit

import AVFoundation
import Foundation

// The maximum number of audio buffers in flight. Setting to two allows one
// buffer to be played while the next is being written.
private let audioBufferCount: Int = 2

// The number of audio samples per buffer. A lower value reduces latency for
// changes but requires more processing but increases the risk of being unable
// to fill the buffers in time. A setting of 1024 represents about 23ms of
// samples.
private let audioBufferSize: AVAudioFrameCount = 2048

public class PongAccessibilitySoundGenerator {

    // The frequency of the note to play
    public var waveFrequency: Float32 = 0.0
    // The frequency at which the note pulses
    public var pulseFrequency: Float32 = 0.0
    
    private(set) var isPlaying = false

    fileprivate let engine: AVAudioEngine = AVAudioEngine()

    fileprivate let playerNode: AVAudioPlayerNode = AVAudioPlayerNode()

    let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)

    fileprivate var audioBuffers: [AVAudioPCMBuffer] = [AVAudioPCMBuffer]()

    fileprivate var bufferIndex: Int = 0

    fileprivate let audioQueue: DispatchQueue = DispatchQueue(label: "com.sphero.pongAccessibility.queue")

    fileprivate let audioSemaphore: DispatchSemaphore = DispatchSemaphore(value: audioBufferCount)

    public init() {
        for _ in 0 ..< audioBufferCount {
            let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioBufferSize)
            audioBuffers.append(audioBuffer)
        }
        
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: audioFormat)

        do {
            try engine.start()
        }
        catch {
            fatalError("Failed to start audio engine.")
        }
    }
    
    private var wavePosition: Float32 = 0.0
    private var pulsePosition: Float32 = 0.0
        
    public var volume: Float32 = 0.1

    public func start() {
        isPlaying = true
        
        audioQueue.async {
            while self.isPlaying {
                // Wait for a buffer to become available.
                self.audioSemaphore.wait()
      
                // Fill the buffer with new samples.
                let audioBuffer = self.audioBuffers[self.bufferIndex]
                let leftChannel = audioBuffer.floatChannelData?[0]
                let rightChannel = audioBuffer.floatChannelData?[1]
                
                for sampleIndex in 0 ..< Int(audioBufferSize) {
                    
                    self.wavePosition += self.waveFrequency / Float32(self.audioFormat.sampleRate)
                    self.wavePosition = self.wavePosition.truncatingRemainder(dividingBy: 1.0)
                    
                    self.pulsePosition += self.pulseFrequency / Float32(self.audioFormat.sampleRate)
                    self.pulsePosition = self.pulsePosition.truncatingRemainder(dividingBy: 1.0)
                    
                    let pulseVolume = 0.5 * sinf(self.pulsePosition * 2.0 * Float32.pi) + 0.5
                    let sampleVolume = self.volume * pulseVolume
                
                    let sample: Float32 = self.wavePosition > 0.5 ? sampleVolume : -sampleVolume
                    
                    leftChannel?[sampleIndex] = sample
                    rightChannel?[sampleIndex] = sample
                }
                audioBuffer.frameLength = audioBufferSize

                // Schedule the buffer for playback and release it for reuse after
                // playback has finished.
                self.playerNode.scheduleBuffer(audioBuffer) {
                    self.audioSemaphore.signal()
                }

                self.bufferIndex = (self.bufferIndex + 1) % self.audioBuffers.count
            }
        }

        playerNode.pan = 0.0
        playerNode.play()
    }
    
    public func stop() {
        self.isPlaying = false
        playerNode.stop()
    }
}

