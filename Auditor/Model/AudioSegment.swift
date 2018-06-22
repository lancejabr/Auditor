//
//  AudioSegment.swift
//  Auditorium
//
//  Created by Lance Jabr on 11/12/16.
//  Copyright © 2016 Code Blue Applications. All rights reserved.
//

import Foundation

import AVFoundation

/// An AudioSegment is a range of audio from a file positioned at a certain time in a track
class AudioSegment {
    
    /// The file to get audio data from.
    let fileURL: URL
    
    /// reloads audio from the disk
    private func loadBuffer() {
        // update the buffer when the frame range has changed
        guard let fileReader = try? AVAudioFile(forReading: fileURL, commonFormat: .pcmFormatFloat32, interleaved: true) else {
            fail(desc: "Couldn't open file!")
            return
        }
        
        self.buffer = AVAudioPCMBuffer(pcmFormat: fileReader.processingFormat, frameCapacity: self.frameCount)
        fileReader.framePosition = self.fileFrameRange.lowerBound
        do {
            try fileReader.read(into: buffer!, frameCount: self.frameCount)
        } catch {
            fail(desc: "Could not read audio from file.")
        }
    }
    
    /// The range of frames in the file this AudioSegment represents.
    var fileFrameRange: Range<AVAudioFramePosition> = 0..<0 {
        didSet {
            self.loadBuffer()
        }
    }
    
    /// The frame in the global timeline that aligns with the first frame of this AudioSegment.
    var frameOffset: Int = 0
    
    /// Constructor
    /// - parameter fileURL: The file to read audio from
    /// - parameter fileFrameRange: The range of fames in the file to represent, or nil to represent the whole file.
    init(fileURL: URL, fileFrameRange: Range<AVAudioFramePosition>?=nil) {
        self.fileURL = fileURL
        
        guard let fileReader = try? AVAudioFile(forReading: fileURL, commonFormat: .pcmFormatFloat32, interleaved: true) else {
            fail(desc: "Couldn't open file!")
            return
        }
        
        self.fileFrameRange = fileFrameRange ?? 0..<fileReader.length
        self.loadBuffer()
    }
    
    /// The number of frames in this AudioSegment
    var frameCount: AVAudioFrameCount {
        return AVAudioFrameCount(self.fileFrameRange.count)
    }
    
    /// The range of frames this AudioSegment ends up having in the global timeline.
    var timelineFrameInterval: Range<Int> {
        return self.frameOffset..<(self.frameOffset + Int(self.frameCount))
    }
    
    /// The actual audio data.
    var buffer: AVAudioPCMBuffer?
}
