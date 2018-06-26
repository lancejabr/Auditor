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
//    var fftMagBuffer = UnsafeMutablePointer<Float>.allocate(capacity: <#T##Int#>)
    var fftOffset: Int = 0
    
    
    let pointsPerColumn: Int = 2
    
    let dataSize = MemoryLayout<Float>.stride
    
    var audioData: MTLBuffer?
    var nBuffers: Int = 0
    var bufferOffset: Int = -1
    
    override func viewDidEndLiveResize() {
        self.setup()
        self.needsDisplay = true
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
        
//        self.preferredFramesPerSecond = 30
        self.isPaused = true
        self.enableSetNeedsDisplay = true
        
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
        self.bufferOffset = self.nBuffers
        
        // allocate space to perform FFT
        self.fftBuffer.deallocate()
        self.fftBuffer = UnsafeMutablePointer<Float>.allocate(capacity: self.fftSize)
        self.fftBuffer.initialize(repeating: 0, count: self.fftSize)
        self.fftOffset = 0
    }
    
    func addAudioData(_ buffer: AVAudioPCMBuffer) {
        
//        self.bufferOffset -= 1
//        if self.bufferOffset == -1 { self.bufferOffset = self.nBuffers - 1 }
//        let target = self.audioData?.contents().assumingMemoryBound(to: Float.self).advanced(by: self.bufferOffset * self.fftSize)
//        target?.assign(repeating: Float(self.nBuffers - self.bufferOffset) / Float(self.nBuffers), count: self.fftSize)
//        DispatchQueue.main.async {
//            if !self.inLiveResize {
//                self.needsDisplay = true
//            }
//        }
        if self.audioData == nil { return }

        var framesLeft = Int(buffer.frameLength)

        while framesLeft > 0 {
            let framesToCopy = Swift.min(self.fftSize - fftOffset, framesLeft)
            self.fftBuffer.advanced(by: fftOffset).assign(from: buffer.floatChannelData![0], count: framesToCopy)
            fftOffset += framesToCopy
            framesLeft -= framesToCopy

            if fftOffset == self.fftSize {
                // TODO: FFT ETC :)
                self.bufferOffset -= 1
                if self.bufferOffset == -1 { self.bufferOffset = self.nBuffers - 1 }
                self.audioData?.contents().assumingMemoryBound(to: Float.self).advanced(by: self.bufferOffset * self.fftSize).assign(from: self.fftBuffer, count: self.fftSize)
                fftOffset = 0
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
        let info = [CInt(self.nBuffers-1), CInt(self.fftSize), CInt(self.bufferOffset)]
        commandEncoder.setVertexBytes(info, length: MemoryLayout<CInt>.stride * 3, index: 1)
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 2 * self.fftSize, instanceCount: self.nBuffers - 2)
        // finish waveform render pass encoding
        commandEncoder.setFrontFacing(.clockwise)
        commandEncoder.endEncoding()
        
        
        
        // commit the buffer for rendering
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
}

protocol AudioSegmentViewDelegate {
    
}
