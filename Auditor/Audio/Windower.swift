//
//  Window.swift
//  Auditor
//
//  Created by Lance Jabr on 7/2/18.
//  Copyright © 2018 Lance Jabr. All rights reserved.
//

import Foundation
import Accelerate

class Windower {
    
    enum Function {
        case rectangular, blackman, hamming
    }
    
    /// The actual window data
    private var window: [Float]
    
    init(length: UInt, function: Function) {
        
        self.window = [Float](repeating: 1, count: Int(length))
        
        switch function {
        case .rectangular:
            break
        case .hamming:
            vDSP_hamm_window(&self.window, length, 0)
        case .blackman:
            vDSP_blkman_window(&self.window, length, 0)
        }
    }
    
    func process(data: UnsafeMutablePointer<Float>) {
        vDSP_vmul(self.window, 1, data, 1, data, 1, UInt(self.window.count))
    }
}
