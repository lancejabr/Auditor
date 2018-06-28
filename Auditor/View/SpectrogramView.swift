//
//  SpectrogramView.swift
//  Auditor
//
//  Created by Lance Jabr on 6/26/18.
//  Copyright © 2018 Lance Jabr. All rights reserved.
//

import Foundation
import Cocoa
import MetalKit
import AVFoundation

/// A view that renders an audio signal using Metal
class SpectrogramView: MTKView {
    
    
    /// MARK: Audio resources
    
    let internalFrameLength: Int = 2048
    var fftBuffer: [Float] = [0]
    var fftOffset: Int = 0
    var fft: FFT?
    
    /// The thickness of each frame in the output spectrum.
    let pointsPerColumn: Int = 2
    /// The number of frames in the output spectrum (changes on view resize).
    var nFrames: Int = 0
    
    /// Data to be passed to Metal for rendering, used as a circular buffer.
    var audioData: MTLBuffer?
    
    /// The most *recent* frame index in `audioData`.
    var frameOffset: Int = -1
    
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
    
    
    override func viewDidEndLiveResize() {
        self.setup()
        self.needsDisplay = true
    }
    
    func setup() {
        // setup the system device
        self.device = MTLCreateSystemDefaultDevice()
        
        // configure the view
        self.colorPixelFormat = .bgra8Unorm
        self.clearColor = MTLClearColorMake(1, 1, 1, 1)
        
        //        self.preferredFramesPerSecond = 30
        self.isPaused = true
        self.enableSetNeedsDisplay = true
        
        // prepare render pass descriptor for border, which needs to specific the .load loadAction
        self.borderRenderPassDescriptor = MTLRenderPassDescriptor()
        self.borderRenderPassDescriptor!.colorAttachments[0].loadAction = .dontCare
        
        // compile the shaders
        guard let defaultLibrary = self.device?.makeDefaultLibrary() else {
            fail(desc: "Couldn't create default Metal library")
            return
        }
        
        // create a default pipeline state which uses XY vertices and a solid color fragment shader
        let defaultPipelineDescriptor = MTLRenderPipelineDescriptor()
        defaultPipelineDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "spectrogram")
        defaultPipelineDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "vertex_color")
        defaultPipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat
        self.defaultPipelineState = try? self.device!.makeRenderPipelineState(descriptor: defaultPipelineDescriptor)
        
        // allocate space for audio
        self.nFrames = Int(self.frame.width) / self.pointsPerColumn
        self.audioData = self.device!.makeBuffer(length:  MemoryLayout<Float>.stride * self.internalFrameLength/2 * nFrames, options: .storageModeShared)
        self.frameOffset = self.nFrames
        
        // allocate space to perform FFT
        self.fftBuffer = [Float](repeating: 0, count: self.internalFrameLength)
        self.fftOffset = 0
        
        // setup FFT processor
        self.fft = FFT(nFrames: self.internalFrameLength)
    }
    
    /// Call this function to add time-domain data to the view for immediate display.
    /// - parameter buffer: An `AVAudioPCMBuffer` of audio data. Format should be non-interleaved or mono. The frameLength of `buffer` can be anything.
    func addAudioData(_ buffer: AVAudioPCMBuffer) {
        
        if self.audioData == nil { return }
        if self.fft == nil { return }
        
        var framesLeft = Int(buffer.frameLength)
        
        while framesLeft > 0 {
            // move frames to internal fft buffer
            let framesToCopy = Swift.min(self.internalFrameLength - self.fftOffset, framesLeft)
            let fftPtr = UnsafeMutablePointer<Float>(mutating: fftBuffer).advanced(by: fftOffset)
            fftPtr.assign(from: buffer.floatChannelData![0], count: framesToCopy)
            
            fftOffset += framesToCopy
            framesLeft -= framesToCopy
            
            // when fft buffer is full...
            if fftOffset == self.internalFrameLength {
                
                // ...process the DFT...
                self.fft!.process(data: self.fftBuffer)
                
                /// ...and transfter to Metal buffer
                self.frameOffset -= 1
                if self.frameOffset == -1 { self.frameOffset = self.nFrames - 1 }
                self.audioData?.contents().assumingMemoryBound(to: Float.self).advanced(by: self.frameOffset * self.internalFrameLength/2).assign(from: self.fft!.powerSpectrum, count: self.internalFrameLength/2)
                
                // reset for next fft
                fftOffset = 0
                
                // redraw the view
                DispatchQueue.main.async {
                    if !self.inLiveResize {
                        self.needsDisplay = true
                    }
                }
            }
        }
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
        
        if self.inLiveResize {return}
        
        // if something's up with Metal we can't do anything
        guard
            let renderPassDescriptor = self.currentRenderPassDescriptor,
            let currentDrawable = self.currentDrawable,
            let device = self.device,
            let defaultPipelineState = self.defaultPipelineState,
            let audioData = self.audioData
            else {
//                fail(desc: "Metal is not set up properly")
                return
        }
        
        // prepare the command buffer and command encoder
        let commandBuffer = device.makeCommandQueue()!.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        commandEncoder.setRenderPipelineState(defaultPipelineState)
        
        // attach resources
        let info = [CInt(self.nFrames-1), CInt(self.internalFrameLength/2), CInt(self.frameOffset)]
        commandEncoder.setVertexBytes(info, length: MemoryLayout<CInt>.stride * 3, index: 1)
        commandEncoder.setVertexBuffer(audioData, offset: 0, index: 0)
        
        // draw the spectrogram
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: self.internalFrameLength, instanceCount: self.nFrames - 2)
        
        // finish waveform render pass encoding
        commandEncoder.endEncoding()
        
        // commit the buffer for rendering
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
}
