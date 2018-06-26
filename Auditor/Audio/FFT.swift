//
//  FFT.swift
//  Auditor
//
//  Created by Lance Jabr on 6/25/18.
//  Copyright © 2018 Lance Jabr. All rights reserved.
//

import Foundation
import Accelerate

class FFT {
    
    let fftSetup: vDSP_DFT_Setup
    let nFrames: Int
    
//    var inReal: [Float]
//    var inImag: [Float]
//    var outReal: [Float]
//    var outImag: [Float]
    
    var complexA: DSPSplitComplex
    var power: [Float]
//    let outData: [Float]
    
    /// - parameter nFrames: The number of Floats that will be passed in on each call to process(...)
    init(nFrames: Int) {
        
        self.nFrames = nFrames
//        self.fftSetup = vDSP_create_fftsetup(vDSP_Length(log2(Float(nFrames))), FFTRadix(FFT_RADIX2))!
        self.fftSetup = vDSP_DFT_zrop_CreateSetup(nil, vDSP_Length(nFrames), .FORWARD)!
        let n_2 = Int(nFrames / 2)
        
//        let n = Int(nFrames)
        
//        self.inImag = [Float](repeating: 0, count: n_2)
//        self.outReal = [Float](repeating: 0, count: n_2)
//        self.outImag = [Float](repeating: 0, count: n_2)
        

        self.complexA = DSPSplitComplex(realp: UnsafeMutablePointer<Float>.allocate(capacity: n_2),
                                        imagp: UnsafeMutablePointer<Float>.allocate(capacity: n_2))
        self.complexA.realp.initialize(repeating: 0, count: n_2)
        self.complexA.imagp.initialize(repeating: 0, count: n_2)

        self.power = [Float](repeating: 0, count: n_2)
        
//        self.outData = [Float](repeating: 0, count: n_2)
    }
    
    deinit {
        vDSP_DFT_DestroySetup(self.fftSetup)
    }
    
    func powerSpectrum(data: UnsafePointer<Float>) -> [Float] {

        let n_2 = UInt(nFrames / 2)
        
        data.withMemoryRebound(to: DSPComplex.self, capacity: Int(nFrames / 2)) { data in
            vDSP_ctoz(data, 2, &self.complexA, 1, n_2)
        }

        vDSP_DFT_Execute(self.fftSetup, self.complexA.realp, self.complexA.imagp, self.complexA.realp, self.complexA.imagp)
        
        var scale = 1/Float(self.nFrames)
        var zero: Float = 0
        var normFactor = DSPSplitComplex(realp: &scale, imagp: &zero)
        vDSP_zvzsml(&self.complexA, 1, &normFactor, &self.complexA, 1, n_2)
        
        vDSP_zvmags(&self.complexA, 1, &self.power, 1, n_2)
        
        return self.power
    }
}
