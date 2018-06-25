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
            let url = Bundle.main.url(forResource: "claire-mid", withExtension: "aif")!
            let file = try AVAudioFile(forReading: url)

            self.attach(player)
            self.connect(self.player, to: self.mainMixerNode, format: file.processingFormat)
            player.scheduleFile(file, at: nil, completionCallbackType: .dataPlayedBack, completionHandler: nil)
            
//            self.inputNode.installTap(onBus: 0, bufferSize: 8192, format: self.inputNode.outputFormat(forBus: 0)) { buffer, time in
//                Swift.print(buffer.frameLength)
//            }
//            self.connect(self.inputNode, to: self.mainMixerNode, format: nil)
            

            try self.start()
            player.play()

        } catch {
            fail(desc: "Could not start audio engine!")
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
