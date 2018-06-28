//
//  AudioEngine.swift
//  Auditor
//
//  Created by Lance Jabr on 6/22/18.
//  Copyright © 2018 Lance Jabr. All rights reserved.
//

import AVFoundation

class AudioEngine: AVAudioEngine {
    
    let player = AVAudioPlayerNode()
    
    override init() {
        super.init()
        
        do {
//            let url = Bundle.main.url(forResource: "claire-mid", withExtension: "aif")!
//            let file = try AVAudioFile(forReading: url)
//            self.attach(player)
//            self.connect(self.player, to: self.mainMixerNode, format: file.processingFormat)
//            player.scheduleFile(file, at: nil, completionCallbackType: .dataPlayedBack, completionHandler: nil)
            
            self.connect(self.inputNode, to: self.mainMixerNode, format: nil)
            self.inputNode.destination(forMixer: self.mainMixerNode, bus: 0)?.volume = 0

            try self.start()
//            player.play()

        } catch {
            fail(desc: "Could not start audio engine!")
        }
    }
    
    var isRecording = false {
        didSet {
            if self.isRecording == oldValue { return }
            if self.isRecording {
                
            }
        }
    }
    
    var playthroughVolume: Float = 0.0 {
        didSet {
            self.inputNode.destination(forMixer: self.mainMixerNode, bus: 0)?.volume = self.playthroughVolume
        }
    }
    
    func availableEffectNames() -> [String] {
        let anyEffect = AudioComponentDescription(componentType: kAudioUnitType_Effect,
                                                  componentSubType: 0,
                                                  componentManufacturer: 0,
                                                  componentFlags: 0,
                                                  componentFlagsMask: 0)
        
        let availableEffects: [AVAudioUnitComponent] = AVAudioUnitComponentManager.shared().components(matching: anyEffect)
        return availableEffects.map() { $0.name }
    }
    
}
