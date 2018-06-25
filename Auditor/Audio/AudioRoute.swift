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
    var description: String {
        if isInput && isOutput {
            return self.name + " (in+out)"
        }
        
        if isInput {
            return self.name + " (in)"
        }
        
        if isOutput {
            return self.name + " (out)"
        }
        
        return self.name
    }
}

/// A static class to retrieve and alter audio routing settings
class AudioRoute {
    
    private class PropertyAddresses {
        static var defaultInput = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultInputDevice,
                                                             mScope: kAudioObjectPropertyScopeGlobal,
                                                             mElement: kAudioObjectPropertyElementMaster)
        
        static var defaultOutput = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                                                              mScope: kAudioObjectPropertyScopeGlobal,
                                                              mElement: kAudioObjectPropertyElementMaster)
        
        static var allDevices = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
                                                           mScope: kAudioObjectPropertyScopeGlobal,
                                                           mElement: kAudioObjectPropertyElementMaster)
    }
    
    
    static var currentInput: AudioObject {
        get {
            var idSize = UInt32(MemoryLayout<AudioObjectID>.size)
            var id: AudioObjectID = 0
            AudioObjectGetPropertyData(
                AudioObjectID(kAudioObjectSystemObject), // which object to query
                &PropertyAddresses.defaultInput, // which property to query
                0, nil, // this is for qualification which we don't use
                &idSize, // how big is the output data
                &id // where to put output data
            )
            
            return AudioObject(id: id)
        }
        set {
            let idSize = UInt32(MemoryLayout<AudioObjectID>.size)
            var id = newValue.id
            AudioObjectSetPropertyData(
                AudioObjectID(kAudioObjectSystemObject),
                &PropertyAddresses.defaultInput,
                0, nil,
                idSize,
                &id
            )
        }
    }
    
    static var currentOutput: AudioObject {
        get {
            var idSize = UInt32(MemoryLayout<AudioObjectID>.size)
            var id: AudioObjectID = 0
            AudioObjectGetPropertyData(
                AudioObjectID(kAudioObjectSystemObject), // which object to query
                &PropertyAddresses.defaultOutput, // which property to query
                0, nil, // this is for qualification which we don't use
                &idSize, // how big is the output data
                &id // where to put output data
            )
            
            return AudioObject(id: id)
        }
        
        set {
            let idSize = UInt32(MemoryLayout<AudioObjectID>.size)
            var id = newValue.id
            AudioObjectSetPropertyData(
                AudioObjectID(kAudioObjectSystemObject),
                &PropertyAddresses.defaultOutput,
                0, nil,
                idSize,
                &id
            )
        }
    }
    
    private static func refreshDevices() {
        var devicesSize = UInt32(0)
        
        AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject), // object to query
            &PropertyAddresses.allDevices, // property to query
            0, nil, // qualification
            &devicesSize // the result
        )
        
        let nDevices = Int(devicesSize) / MemoryLayout<AudioDeviceID>.size
        var IDs: [AudioDeviceID] = [AudioDeviceID](repeating: 0, count: nDevices)
        
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), // which object to query
            &PropertyAddresses.allDevices, // which property to query
            0, nil, // this is for qualification which we don't use
            &devicesSize, // how big is the output data
            &IDs // where to put output data
        )
        
        cachedAvailableDevices = IDs.map() { AudioObject(id: $0) }
    }

    private static var cachedAvailableDevices: [AudioObject]?
    
    static var availableDevices: [AudioObject] {
        if cachedAvailableDevices == nil {
            refreshDevices()
            AudioObjectAddPropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject),
                &PropertyAddresses.allDevices,
                nil) { numAddresses, addresses in
                    refreshDevices()
            }
        }
        
        return cachedAvailableDevices!
    }
    
    static var availableInputs: [AudioObject] {
        return availableDevices.filter() { $0.isInput }
    }
    
    static var availableOutputs: [AudioObject] {
        return availableDevices.filter() { $0.isOutput }
    }
}
