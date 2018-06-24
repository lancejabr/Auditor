//
//  AppView.swift
//  Auditor
//
//  Created by Lance Jabr on 6/21/18.
//  Copyright © 2018 Lance Jabr. All rights reserved.
//

import Cocoa

class AppView: NSView {
    
//    var delegate: TracksViewDelegate?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.wantsLayer = true
        self.layer!.isOpaque = true
        self.layer!.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        self.registerForDraggedTypes([.fileURL])
        self.allowedTouchTypes = [.direct, .indirect]
    }
    
    // MARK: - Drag and Drop
    
    let supportedFileTypes = ["wav", "aac", "m4a", "mp3", "ogg", "aif", "aifc", "aiff"]
    
    /// Check if we support the drag in progress
    ///  - parameter drag: An NSDraggingInfo passed to an NSDraggingDestination delegate function.
    ///  - returns: The URL of the supported file, or nil if no supported file is present.
    func fileURLFor(drag: NSDraggingInfo) -> URL? {
        if let propList = drag.draggingPasteboard().propertyList(forType: NSPasteboard.PasteboardType.fileURL) as? String {
            if let url = URL(string: propList) {
                if supportedFileTypes.contains(url.pathExtension) {
                    return url
                }
            }
        }
        return nil
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        // if we don't support the file being dragged, return a default drag operation to reject
        return fileURLFor(drag: sender) != nil ? .copy : NSDragOperation()
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {}
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        sender.animatesToDestination = true
        
        return true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let url = fileURLFor(drag: sender) {
            if let audSegView = self.subviews.first as? AudioSegmentView {
                audSegView.audioSegment = AudioSegment(fileURL: url)
            }
            return true
        }
        
        return false
    }
    
    override func concludeDragOperation(_ sender: NSDraggingInfo?) {}
    
    // - MARK: - Zooming
    
    @IBAction func handleGesture(gestureRecognizer: NSMagnificationGestureRecognizer) {
        Swift.print(gestureRecognizer.magnification)
        let scrollView = self.subviews.first as! NSScrollView
        
//        scrollView.
        
    }
//    var hairlineBorderFrame: NSRect {
//        return CGRectMake(headerViewWidth - hairlineWidth, 0, hairlineWidth, self.bounds.size.height)
//    }
//
//    override func draw(_ rect: NSRect) {
//        super.draw(rect)
//
//        NSColor(calibratedWhite: 0.9, alpha: 1).set()
//        NSBezierPath.fill(rect: hairlineBorderFrame)
//    }
    
}

extension AppView: NSGestureRecognizerDelegate {
    
}
