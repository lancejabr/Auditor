//
//  Window.swift
//  Auditor
//
//  Created by Lance Jabr on 7/2/18.
//  Copyright © 2018 Lance Jabr. All rights reserved.
//

import Foundation
import Accelerate

class Window {
    
    enum Function {
        case rectangular, blackman, hamming
    }
    
    /// The actual window data
    private var buffer: [Float]
    
    init(length: UInt, function: Function) {
        
        self.buffer = [Float](repeating: 1, count: Int(length))
        
        switch function {
        case .rectangular:
            break
        case .hamming:
            vDSP_hamm_window(&self.buffer, length, 0)
        case .blackman:
            vDSP_blkman_window(&self.buffer, length, 0)
        }
        
    }
    
    func process(data: UnsafeMutablePointer<Float>) {
        vDSP_vmul(self.buffer, 1, data, 1, data, 1, UInt(self.buffer.count))
    }
    
}
