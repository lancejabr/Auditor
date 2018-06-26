//
//  FFT.swift
//  Auditor
//
//  Created by Lance Jabr on 6/25/18.
//  Copyright © 2018 Lance Jabr. All rights reserved.
//

import Foundation
import Accelerate

/// A real-to-complex FFT manager wrapping the Accelerate framework.
class FFT {
    
    /// The number of real, time-domain samples that will be passed in each process block.
    let nFrames: Int

    /// A struct used by Accelerate to perform the DFT.
    private let fftSetup: vDSP_DFT_Setup
    
    /// After a call to `process`, this will contain the complex scaled FFT output.
    var fftOutput: DSPSplitComplex
    
    /// after a call to `process`, this will contain the power (mag^2) spectrum.
    var powerSpectrum: [Float]
    
    /// - parameter nFrames: The number of Floats that will be passed in on each call to `process`. Must be a power of 2.
    init(nFrames: Int) {
        
        self.nFrames = nFrames
        
        // create the Accelerate helper struct
        self.fftSetup = vDSP_DFT_zrop_CreateSetup(nil, vDSP_Length(nFrames), .FORWARD)!
        
        // allocate space for the complex output
        let n_2 = Int(nFrames / 2)
        self.fftOutput = DSPSplitComplex(realp: UnsafeMutablePointer<Float>.allocate(capacity: n_2),
                                        imagp: UnsafeMutablePointer<Float>.allocate(capacity: n_2))
        self.fftOutput.realp.initialize(repeating: 0, count: n_2)
        self.fftOutput.imagp.initialize(repeating: 0, count: n_2)

        // allocate space for the power spectrum
        self.powerSpectrum = [Float](repeating: 0, count: n_2)
    }
    
    deinit {
        vDSP_DFT_DestroySetup(self.fftSetup)
    }
    
    /// Process a block of real data.
    /// - parameter data: A pointer to time-domain Float data, which must contain `nFrames` Floats.
    /// - return: A DSPSplitComplex struct with the scaled FFT (1/N) output. For a spectrum, query `powerSpectrum` after this method executes.
    func process(data: UnsafePointer<Float>) -> DSPSplitComplex {

        let n_2 = UInt(nFrames / 2)
        
        // split the real data into a complex struct
        data.withMemoryRebound(to: DSPComplex.self, capacity: Int(nFrames / 2)) { data in
            vDSP_ctoz(data, 2, &self.fftOutput, 1, n_2)
        }

        // execute DFT
        vDSP_DFT_Execute(self.fftSetup, self.fftOutput.realp, self.fftOutput.imagp, self.fftOutput.realp, self.fftOutput.imagp)
        
        // scale the output by 1/N
        var scale = 1/Float(self.nFrames)
        var zero: Float = 0
        var normFactor = DSPSplitComplex(realp: &scale, imagp: &zero)
        vDSP_zvzsml(&self.fftOutput, 1, &normFactor, &self.fftOutput, 1, n_2)
        
        // calculate the squared magnitude of each output datum
        vDSP_zvmags(&self.fftOutput, 1, &self.powerSpectrum, 1, n_2)
        
        return self.fftOutput
    }
}
