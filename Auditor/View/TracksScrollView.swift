//
//  TracksScrollView.swift
//  Auditor
//
//  Created by Lance Jabr on 6/21/18.
//  Copyright © 2018 Lance Jabr. All rights reserved.
//

import Cocoa

class TracksScrollView: NSScrollView {
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    var horizontalZoom: CGFloat = 1
}
