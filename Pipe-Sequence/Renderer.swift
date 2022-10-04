//
//  Renderer.swift
//  Pipe-Sequence
//
//  Created by Dong-Min KIM on 2022/10/04.
//

import Foundation
import Metal
import MetalKit

protocol RenderDestinationProvider {
    var currentRenderPassDescriptor: MTLRenderPassDescriptor? { get }
    var currentDrawable: CAMetalDrawable? { get }
    var colorPixelFormat: MTLPixelFormat { get set }
    var depthStencilPixelFormat: MTLPixelFormat { get set }
    var sampleCount: Int { get set }
}

// The max number of command buffers in flight
let kMaxBuffersInFlight: Int = 3

// Vertex data for an image plane
let kImagePlaneVertexData: [Float] = [
    -1.0, -1.0,  0.0, 1.0,
    1.0, -1.0,  1.0, 1.0,
    -1.0,  1.0,  0.0, 0.0,
    1.0,  1.0,  1.0, 0.0,
]

class Renderer {
    let device: MTLDevice
    let inFlightSemaphore = DispatchSemaphore(value: kMaxBuffersInFlight)
    var renderDestination: RenderDestinationProvider
    
    // Metal Objects
    var commandQueue: MTLCommandQueue!
    var imagePlaneVertexBuffer: MTLBuffer!
    var capturedImagePipelineState: MTLRenderPipelineState!
    
    init(device: MTLDevice, renderDestination: RenderDestinationProvider) {
        self.device = device
        self.renderDestination = renderDestination
        loadMetal()
    }

    func update(){
        let _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        if let commandBuffer = commandQueue.makeCommandBuffer(){
            commandBuffer.label = "MyCommand"
            
            if let renderPassDescriptor = renderDestination.currentRenderPassDescriptor, let currentDrawable = renderDestination.currentDrawable, let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                
                renderEncoder.label = "MyRenderEncoder"
                
                drawCapturedImage(renderEncoder: renderEncoder)
                
                // Schedule a present once the framebuffer is complete using the current drawable
                commandBuffer.present(currentDrawable)
            }
            
            // Finalize rendering here & push the command buffer to the GPU
            commandBuffer.commit()
        }
    }
    
    // MARK: - Private
    
    func loadMetal() {
        renderDestination.depthStencilPixelFormat = .depth32Float_stencil8
        renderDestination.colorPixelFormat = .bgra8Unorm
        renderDestination.sampleCount = 1
        
        let imageVertexDescriptor = MTLVertexDescriptor()
        
        // Positions.
        imageVertexDescriptor.attributes[0].format = .float2
        imageVertexDescriptor.attributes[0].offset = 0
        imageVertexDescriptor.attributes[0].bufferIndex = Int(kBufferIndexMeshPositions.rawValue)
        
        // Texture Coordinates.
        imageVertexDescriptor.attributes[1].format = .float2
        imageVertexDescriptor.attributes[1].offset = 8
        imageVertexDescriptor.attributes[0].bufferIndex = Int(kBufferIndexMeshPositions.rawValue)
        
        // Buffer layout
        imageVertexDescriptor.layouts[0].stride = 16
        imageVertexDescriptor.layouts[0].stepRate = 1
        imageVertexDescriptor.layouts[0].stepFunction = .perVertex
        
        let capturedImagePipelineStateDescriptor = MTLRenderPipelineDescriptor()
        capturedImagePipelineStateDescriptor.label = "MyCapturedImagePipeline"
        capturedImagePipelineStateDescriptor.sampleCount = renderDestination.sampleCount
//        capturedImagePipelineStateDescriptor.vertexFunction =
//        capturedImagePipelineStateDescriptor.fragmentFunction =
        capturedImagePipelineStateDescriptor.vertexDescriptor = imageVertexDescriptor
        capturedImagePipelineStateDescriptor.colorAttachments[0].pixelFormat = renderDestination.colorPixelFormat
        capturedImagePipelineStateDescriptor.depthAttachmentPixelFormat = renderDestination.depthStencilPixelFormat
        capturedImagePipelineStateDescriptor.stencilAttachmentPixelFormat = renderDestination.depthStencilPixelFormat
        
        do {
            try capturedImagePipelineState = device.makeRenderPipelineState(descriptor: capturedImagePipelineStateDescriptor)
        } catch let error {
            print ("Failed to created captured image pipeline state, error \(error)")
        }
        
        let imagePlaneVertexSize = kImagePlaneVertexData.count * MemoryLayout<Float>.size
        imagePlaneVertexBuffer = device.makeBuffer(bytes: kImagePlaneVertexData, length: imagePlaneVertexSize, options: [])
        imagePlaneVertexBuffer.label = "ImagePlaneVertexBuffer"
    }
    
    func drawCapturedImage(renderEncoder: MTLRenderCommandEncoder) {
        
        // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool
        renderEncoder.pushDebugGroup("DrawCapturedImage")
        
        // Set render command encoder state
        renderEncoder.setCullMode(.none)
//        renderEncoder.setRenderPipelineState(<#T##pipelineState: MTLRenderPipelineState##MTLRenderPipelineState#>)
//        renderEncoder.setDepthStencilState(<#T##depthStencilState: MTLDepthStencilState?##MTLDepthStencilState?#>)
        
        // Set mesh's vertex buffers
//        renderEncoder.setVertexBuffer(<#T##buffer: MTLBuffer?##MTLBuffer?#>, offset: <#T##Int#>, index: <#T##Int#>)
        
        // Set any textures read/sampled from our render pipeline
        
        // Draw each submesh of our mesh
//        renderEncoder.drawPrimitives(type: <#T##MTLPrimitiveType#>, vertexStart: <#T##Int#>, vertexCount: <#T##Int#>)
        
        renderEncoder.popDebugGroup()
    }
}
