//
//  LiveWaveformView.swift
//  Auditor
//
//  Created by Lance Jabr on 6/23/18.
//  Copyright © 2018 Lance Jabr. All rights reserved.
//

import Cocoa

class LiveWaveformView: NSView {
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
    }

    
}
