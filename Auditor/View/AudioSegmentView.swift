//
//  SignalView.swift
//  Space Audity
//
//  Created by Lance Jabr on 10/16/16.
//  Copyright © 2016 Code Blue Applications. All rights reserved.
//

import Foundation
import Cocoa
import MetalKit
import AVFoundation

/// A view that renders an audio signal using Metal
class AudioSegmentView: MTKView, MTKViewDelegate {
    
    // MARK: Audio Properties
    
    var audioSegment: AudioSegment? = nil {
        didSet {
            guard let buffer = audioSegment?.buffer else {
                fail(desc: "Couldn't get buffer from audio segment.")
                return
            }
            
            // create the x and y coordinates for the signal...
            // ...x coordinates
            let widthPerFrame = 2.0 / (Float32(buffer.frameLength) - 1)
            let t = (0..<Int(buffer.frameLength)).map { i in widthPerFrame * Float32(i) - 1 }
            self.xCoords = self.device!.makeBuffer(bytes: t, length: Int(buffer.frameLength) * MemoryLayout<Float32>.size, options: .storageModeShared)
            
            // ...y coordinates
            self.yCoords = self.device!.makeBuffer(bytes: buffer.floatChannelData![0], length: Int(buffer.frameLength) * MemoryLayout<Float32>.size, options: .storageModeShared)
            
            // create the memory for the border
            // we can make the X coordinates now
            let borderX: [Float] = [-1, 1, -1, -1, 1, 1, -1, 1, -1, -1, 1, 1]
            self.borderX = self.device!.makeBuffer(bytes: borderX, length: 12 * MemoryLayout<Float>.size, options: .storageModeShared)
            
            // we can allocate memory for Y coordinates but we'll fill in values later
            self.borderY = self.device!.makeBuffer(length: 12 * MemoryLayout<Float32>.size, options: .storageModeShared)
            
            // render the audio
            self.needsDisplay = true
        }
    }
    
    
    // MARK: Metal Resources
    
    /// the `pipelineState` contains the shaders for the audio signal
    var defaultPipelineState: MTLRenderPipelineState?
    
    /// the *t* vector (normalized x coordinates for the signal)
    var xCoords: MTLBuffer?
    /// the *y* vector (normalized y coordinates for the signal)
    var yCoords: MTLBuffer?
    
    var borderRenderPassDescriptor: MTLRenderPassDescriptor?
    var borderX: MTLBuffer?
    var borderY: MTLBuffer?
    
    /// the matrix used to scale and translate the audio waveform
    var transformBuffer: MTLBuffer?
    
    
    // MARK: Instance Methods
    
    func setup() {
        if self.device != nil { return }
        
        // setup the system device
        self.device = MTLCreateSystemDefaultDevice()
        
        // configure the view
        self.colorPixelFormat = .bgra8Unorm
        self.clearColor = MTLClearColorMake(1, 1, 1, 1)
        
        // opt-in to event-driven drawing, so the view only updates when needed
        self.enableSetNeedsDisplay = true
        self.isPaused = true
        self.preferredFramesPerSecond = 60
        
        // prepare render pass descriptor for border, which needs to specific the .load loadAction
        self.borderRenderPassDescriptor = MTLRenderPassDescriptor()
        self.borderRenderPassDescriptor!.colorAttachments[0].loadAction = .load
        
        // compile the shaders
        guard let defaultLibrary = self.device?.makeDefaultLibrary() else {
            Swift.print("Error: couldn't create default Metal library")
            return
        }
        
        // create a default pipeline state which uses XY vertices and a solid color fragment shader
        let defaultPipelineDescriptor = MTLRenderPipelineDescriptor()
        defaultPipelineDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "xy_vertex")
        defaultPipelineDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "solid_color")
        defaultPipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat
        self.defaultPipelineState = try? self.device!.makeRenderPipelineState(descriptor: defaultPipelineDescriptor)
    }
    
    required init(frame: NSRect) {
        super.init(frame: frame, device: nil)
        
        self.setup()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        
        self.setup()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // TODO: optimize using rect
        
        // TODO: optimize using inLiveResize

        //        if self.inLiveResize {Swift.print("resize");return} else {Swift.print("not resize")}
        
        guard let buffer = self.audioSegment?.buffer else { return }
        
        // if something's up with Metal we can't do anything
        guard
            let renderPassDescriptor = self.currentRenderPassDescriptor,
            let currentDrawable = self.currentDrawable,
            let device = self.device,
            let defaultPipelineState = self.defaultPipelineState,
            let borderRenderPassDescriptor = self.borderRenderPassDescriptor
            else {
                fail(desc: "Metal is not set up properly")
                return
        }
        
        
        // create the command buffer
        let commandBuffer = device.makeCommandQueue()!.makeCommandBuffer()!
        
        // 1 - encode a rendering pass for the waveform
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        commandEncoder.setRenderPipelineState(defaultPipelineState)
        // attach resources
        commandEncoder.setVertexBuffer(self.xCoords, offset: 0, index: 0) // x coords of waveform
        commandEncoder.setVertexBuffer(self.yCoords, offset: 0, index: 1) // y coords of waveform
        let colorBuffer: [Float32] = [0.25, 0.35, 0.5, 1]
        commandEncoder.setFragmentBytes(colorBuffer, length: colorBuffer.count * MemoryLayout<Float32>.size, index: 0) // color of waveform
        // draw the waveform as a linestrip
        commandEncoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: Int(buffer.frameLength))
        commandEncoder.drawPrimitives(type: .point,
                                      vertexStart: Int(self.audioSegment!.fileFrameRange.lowerBound),
                                      vertexCount: Int(self.audioSegment!.frameCount) + 1)
        // finish waveform render pass encoding
        commandEncoder.endEncoding()
        
        
        // 2 - encode a rendering pass for the view borders
        
        // create the y coordinates
//        let height = Float(self.bounds.size.height)
//        let borderWidth: Float = 3
//        let normalizedBorderWidth = 2 * borderWidth / height
//        let borderY: [Float] = [1, 1, 1 - normalizedBorderWidth,
//                                1 - normalizedBorderWidth, 1, 1 - normalizedBorderWidth,
//                                -1 + normalizedBorderWidth, -1 + normalizedBorderWidth, -1,
//                                -1, -1 + normalizedBorderWidth, -1]
//        memcpy(self.borderY!.contents(), borderY, 12 * MemoryLayout<Float>.size)
        
        // create the render pass
//        borderRenderPassDescriptor.colorAttachments[0].texture = currentDrawable.texture
//        let commandEncoder2 = commandBuffer.makeRenderCommandEncoder(descriptor: borderRenderPassDescriptor)!
//        commandEncoder2.setRenderPipelineState(defaultPipelineState)
//        // attach resources
//        commandEncoder2.setVertexBuffer(self.borderX, offset: 0, index: 0) // x coords of border
//        commandEncoder2.setVertexBuffer(self.borderY, offset: 0, index: 1) // y coords of border
//        commandEncoder2.setFragmentBuffer(self.colorBuffer, offset:0, index:0)
//        commandEncoder2.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 12)
//        commandEncoder2.endEncoding()
        
        
        // commit the buffer for rendering
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // TODO
        Swift.print("RESIZE")
    }
    
    func draw(in view: MTKView) {
        
    }
}

protocol AudioSegmentViewDelegate {
    
}
