//
//  FFT.swift
//  Auditor
//
//  Created by Lance Jabr on 6/25/18.
//  Copyright © 2018 Lance Jabr. All rights reserved.
//

import Foundation
import Accelerate

/// A real-to-complex FFT processor using the Accelerate framework.
class FFT {
    
    /// The number of real, time-domain samples that will be processed in each frame.
    let nFrames: UInt
    
    /// The number of zeros to add to the signal data on each frame.
    let zeroPad: UInt

    /// A struct used by Accelerate to perform the DFT.
    private let fftSetup: vDSP_DFT_Setup
    
    /// incoming data is fed into this buffer
    private var input: [Float]
    
    /// The windowing object of this FFT
    var windower: Windower?
    
    /// This object can eat samples at any rate–you don't have to pass in the same number of frames each time. When a new chunk of data has been processed, this will be set to `true`. You can set it to `false` to indicate you have used that output data.
    var newOutput = false
    
    /// After a call to `process`, this will contain the complex scaled FFT output.
    var fftOutput: DSPSplitComplex
    
    /// After a call to `process`, this will contain the power (mag^2) spectrum.
    var powerSpectrum: [Float]
    
    /// - parameter nFrames: The number of Floats that will be passed in on each call to `process`.
    /// - parameter zeroPad: The number of zeros that should be added to the end of passed in data. `nFrames + zeroPad` must be a power of 2.
    init(nFrames: UInt, zeroPad: UInt) {

        self.nFrames = nFrames
        self.zeroPad = zeroPad
        
        let totalLength = nFrames + zeroPad
        
        // create the Accelerate helper struct
        self.fftSetup = vDSP_DFT_zrop_CreateSetup(nil, vDSP_Length(totalLength / 2), .FORWARD)!
        
        // allocate space for the complex output
        let n_2 = Int((totalLength) / 2)
        self.fftOutput = DSPSplitComplex(realp: UnsafeMutablePointer<Float>.allocate(capacity: n_2),
                                         imagp: UnsafeMutablePointer<Float>.allocate(capacity: n_2))
        self.fftOutput.realp.initialize(repeating: 0, count: n_2)
        self.fftOutput.imagp.initialize(repeating: 0, count: n_2)
        
        // allocate space for the power spectrum
        self.powerSpectrum = [Float](repeating: 0, count: n_2)
        
        // create the windowing object
        self.windower = Windower(length: self.nFrames, function: .blackman)
        
        // allocate space for input
        self.input = [Float](repeating: 0, count: Int(self.nFrames))
    }
    
    deinit {
        vDSP_DFT_DestroySetup(self.fftSetup)
    }
    
    /// Process a block of real data.
    /// - parameter data: A pointer to time-domain Float data
    func process(data: UnsafePointer<Float>) {
        
        let n_2 = UInt((self.nFrames + self.zeroPad) / 2)
        
        // copy into input
        vDSP_mmov(data, &self.input, self.nFrames, 1, self.nFrames, self.nFrames)
        
        // window the input
        self.windower?.process(data: &self.input)
        
        // zero out the complex output struct
        var zero: Float = 0
        vDSP_vsmul(self.fftOutput.realp, 1, &zero, self.fftOutput.realp, 1, n_2)
        vDSP_vsmul(self.fftOutput.imagp, 1, &zero, self.fftOutput.imagp, 1, n_2)

        // split the real data into a complex struct
        UnsafePointer<Float>(self.input).withMemoryRebound(to: DSPComplex.self, capacity: Int(self.nFrames / 2)) { data in
            vDSP_ctoz(data, 2, &self.fftOutput, 1, n_2)
        }
        
        // execute DFT
        vDSP_DFT_Execute(self.fftSetup, self.fftOutput.realp, self.fftOutput.imagp, self.fftOutput.realp, self.fftOutput.imagp)
        
        // scale the output by 1/N
        var scale = 1/Float(self.nFrames)
        var normFactor = DSPSplitComplex(realp: &scale, imagp: &zero)
        vDSP_zvzsml(&self.fftOutput, 1, &normFactor, &self.fftOutput, 1, n_2)
        
        // calculate the squared magnitude of each output datum
        vDSP_zvmags(&self.fftOutput, 1, &self.powerSpectrum, 1, n_2)
    }
}
