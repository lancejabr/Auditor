//
//  LiveWaveformView.swift
//  Auditor
//
//  Created by Lance Jabr on 6/23/18.
//  Copyright © 2018 Lance Jabr. All rights reserved.
//

import Foundation
import Cocoa
import MetalKit
import AVFoundation

/// A view that renders an audio signal using Metal
class LiveAudioView: MTKView {
    
    let fftSize: Int = 2048
    var fftBuffer = UnsafeMutablePointer<Float>.allocate(capacity: 0)
    var fftOffset: Int = 0
    
    let pointsPerColumn: Int = 3
    
    let dataSize = MemoryLayout<Float>.stride
    
    var audioData: MTLBuffer?
    var nBuffers: Int = 0
    var lastBufferOffset: Int = 0
    
    override func viewDidEndLiveResize() {
        self.setup()
        self.isPaused = false
    }
    
    override func viewWillStartLiveResize() {
        self.isPaused = true
        
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
        // setup the system device
        self.device = MTLCreateSystemDefaultDevice()
        
        // configure the view
        self.colorPixelFormat = .bgra8Unorm
        self.clearColor = MTLClearColorMake(1, 1, 1, 1)
        
        self.preferredFramesPerSecond = 30
        self.isPaused = false
        
        // prepare render pass descriptor for border, which needs to specific the .load loadAction
        self.borderRenderPassDescriptor = MTLRenderPassDescriptor()
        self.borderRenderPassDescriptor!.colorAttachments[0].loadAction = .dontCare
        
        // compile the shaders
        guard let defaultLibrary = self.device?.makeDefaultLibrary() else {
            Swift.print("Error: couldn't create default Metal library")
            return
        }
        
        // create a default pipeline state which uses XY vertices and a solid color fragment shader
        let defaultPipelineDescriptor = MTLRenderPipelineDescriptor()
        defaultPipelineDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "spectrogram")
        defaultPipelineDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "vertex_color")
        defaultPipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat
        self.defaultPipelineState = try? self.device!.makeRenderPipelineState(descriptor: defaultPipelineDescriptor)
        
        // allocate space for audio
        self.nBuffers = Int(self.frame.width) / self.pointsPerColumn
        self.audioData = self.device!.makeBuffer(length: self.dataSize * self.fftSize * nBuffers, options: .storageModeShared)
        self.lastBufferOffset = -1
        
        // allocate space to perform FFT
        self.fftBuffer = UnsafeMutablePointer<Float>.allocate(capacity: self.fftSize)
        self.fftOffset = 0
    }
    
    func addAudioData(_ buffer: AVAudioPCMBuffer) {
        
        if self.audioData == nil { return }
        if self.isPaused { return }
        
        var framesLeft = Int(buffer.frameLength)
        
        while framesLeft > 0 {
            let framesToCopy = Swift.min(self.fftSize - fftOffset, framesLeft)
            self.fftBuffer.advanced(by: fftOffset).assign(from: buffer.floatChannelData![0], count: framesToCopy)
            fftOffset += framesToCopy
            framesLeft -= framesToCopy
            
            if fftOffset == self.fftSize {
                // TODO: FFT ETC :)
                self.lastBufferOffset += 1
                if self.lastBufferOffset == nBuffers { self.lastBufferOffset = 0 }
                let target = self.audioData?.contents().advanced(by: self.lastBufferOffset * fftSize * dataSize)
                target?.copyMemory(from: self.fftBuffer, byteCount: dataSize * fftSize)
                fftOffset = 0
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
        
        // TODO: optimize using rect
        
        
        // if something's up with Metal we can't do anything
        guard
            let renderPassDescriptor = self.currentRenderPassDescriptor,
            let currentDrawable = self.currentDrawable,
            let device = self.device,
            let defaultPipelineState = self.defaultPipelineState,
            let audioData = self.audioData
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
        commandEncoder.setVertexBuffer(audioData, offset: 0, index: 0)
        var info = [CInt(nBuffers), CInt(self.fftSize), CInt(self.lastBufferOffset)]
        commandEncoder.setVertexBytes(&info, length: MemoryLayout<CInt>.stride * 3, index: 1)
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 2 * self.fftSize, instanceCount: self.nBuffers - 1)
//        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
        // finish waveform render pass encoding
        commandEncoder.endEncoding()
        
        
        
        // commit the buffer for rendering
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
}

protocol AudioSegmentViewDelegate {
    
}
