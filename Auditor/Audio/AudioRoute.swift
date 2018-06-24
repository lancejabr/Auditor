//
//  Routing.swift
//  Auditor
//
//  Created by Lance Jabr on 6/23/18.
//  Copyright © 2018 Lance Jabr. All rights reserved.
//

import Foundation
import CoreAudio

/// A Core Audio AudioObject
class AudioObject {
    let name: String
    fileprivate let id: AudioObjectID
    
    init(id: AudioObjectID) {
        self.id = id
        
        // get the name for the object:
        var nameSize = UInt32(MemoryLayout<CChar>.size * 256)
        var name = String(repeating: " ", count: 256) as CFString
        var propAddress = AudioObjectPropertyAddress(mSelector: kAudioObjectPropertyName,
                                                     mScope: kAudioObjectPropertyScopeGlobal,
                                                     mElement: kAudioObjectPropertyElementMaster)
        AudioObjectGetPropertyData(
            self.id, // which object to query
            &propAddress, // which property to query
            0, nil, // this is for qualification which we don't use
            &nameSize, // how big is the output data
            &name // where to put output data
        )
        
        self.name = String(name).trimmingCharacters(in: NSCharacterSet.whitespaces)
    }
    
    var isOutput: Bool {
        // check the size of the output streams
        var streamsSize = UInt32(0)
        var propAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreams,
                                                     mScope: kAudioObjectPropertyScopeOutput,
                                                     mElement: kAudioObjectPropertyElementMaster)
        AudioObjectGetPropertyDataSize(
            self.id,
            &propAddress,
            0, nil,
            &streamsSize)
        
        // if there are any output streams, then it is an output
        return streamsSize > 0
    }
    
    var isInput: Bool {
        // check the size of the input streams
        var streamsSize = UInt32(0)
        var propAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreams,
                                                     mScope: kAudioObjectPropertyScopeInput,
                                                     mElement: kAudioObjectPropertyElementWildcard)
        
        AudioObjectGetPropertyDataSize(
            self.id,
            &propAddress,
            0, nil,
            &streamsSize)
        
        // if there are any input streams, then it is an input
        return streamsSize > 0
    }
}

extension AudioObject: Equatable {
    static func == (lhs: AudioObject, rhs: AudioObject) -> Bool {
        return lhs.id == rhs.id
    }
}

extension AudioObject: CustomStringConvertible {
    var description: String { return self.name }
}

/// A static class to retrieve and alter audio routing settings
class AudioRoute {
    
    static var currentInput: AudioObject? {
        
        var idSize = UInt32(MemoryLayout<AudioObjectID>.size)
        var id: AudioObjectID = 0
        var propAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultInputDevice,
                                                     mScope: kAudioObjectPropertyScopeGlobal,
                                                     mElement: kAudioObjectPropertyElementMaster)
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), // which object to query
            &propAddress, // which property to query
            0, nil, // this is for qualification which we don't use
            &idSize, // how big is the output data
            &id // where to put output data
        )
        
        if id == 0 { return nil }
        
        return AudioObject(id: id)
    }
    
    static var currentOutput: AudioObject {
        var idSize = UInt32(MemoryLayout<AudioObjectID>.size)
        var id: AudioObjectID = 0
        var propAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                                                     mScope: kAudioObjectPropertyScopeGlobal,
                                                     mElement: kAudioObjectPropertyElementMaster)
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), // which object to query
            &propAddress, // which property to query
            0, nil, // this is for qualification which we don't use
            &idSize, // how big is the output data
            &id // where to put output data
        )
        
        return AudioObject(id: id)
    }
    
    static var availableDevices: [AudioObject] {
        
        var devicesSize = UInt32(0)
        var propAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
                                                     mScope: kAudioObjectPropertyScopeGlobal,
                                                     mElement: kAudioObjectPropertyElementMaster)
        
        AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject), // object to query
            &propAddress, // property to query
            0, nil, // qualification
            &devicesSize // the result
        )
        
        let nDevices = Int(devicesSize) / MemoryLayout<AudioDeviceID>.size
        var IDs: [AudioDeviceID] = [AudioDeviceID](repeating: 0, count: nDevices)
        
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), // which object to query
            &propAddress, // which property to query
            0, nil, // this is for qualification which we don't use
            &devicesSize, // how big is the output data
            &IDs // where to put output data
        )
        
        return IDs.map() { AudioObject(id: $0) }
        
    }
    
    static var availableInputs: [AudioObject] {
        return availableDevices.filter() { $0.isInput }
    }
    
    static var availableOutputs: [AudioObject] {
        return availableDevices.filter() { $0.isOutput }
    }
}
