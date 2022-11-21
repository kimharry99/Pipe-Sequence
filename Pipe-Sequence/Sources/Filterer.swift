//
//  Filterer.swift
//  Pipe-Sequence
//
//  Created by Dong-Min KIM on 2022/11/07.
//

import Foundation
import Metal
import MetalKit

class Filterer {
    let device: MTLDevice
    let arTextures: ARTextureContainer
    
    var renderPassDescriptor: MTLRenderPassDescriptor!
    var renderPipelineState: MTLRenderPipelineState!
    var imagePlaneVertexBuffer: MTLBuffer!
    
    // Vertex data for an image plane
    let kImagePlaneVertexData: [Float] = [
        -1.0, -1.0,  0.0, 1.0,
        1.0, -1.0,  1.0, 1.0,
        -1.0,  1.0,  0.0, 0.0,
        1.0,  1.0,  1.0, 0.0,
    ]

    init(device: MTLDevice, arTextures: ARTextureContainer) {
        self.device = device
        self.arTextures = arTextures
        loadMetal()
    }
    
    func filter(commandBuffer: MTLCommandBuffer) {
        // 렌더링
        if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            
            filterWithInfo(renderEncoder: renderEncoder)
            
            renderEncoder.endEncoding()
        }
        return
    }
    
    // MARK: - Private
    func loadMetal() {
        // init MTLBuffer
        let imagePlaneVertexSize = kImagePlaneVertexData.count * MemoryLayout<Float>.size
        imagePlaneVertexBuffer = device.makeBuffer(bytes: kImagePlaneVertexData, length: imagePlaneVertexSize, options: [])
        imagePlaneVertexBuffer.label = "ImagePlaneVertexBuffer"
        
        let defaultLibrary = device.makeDefaultLibrary()!
        
        let capturedImageVertexFunction = defaultLibrary.makeFunction(name: "capturedImageVertexTransform")!
        let filterDepthFragmentFunction = defaultLibrary.makeFunction(name: "filterDepthFragmentShader")!
        
        let imageVertexDescriptor = MTLVertexDescriptor()
        
        // Positions.
        imageVertexDescriptor.attributes[0].format = .float2
        imageVertexDescriptor.attributes[0].offset = 0
        imageVertexDescriptor.attributes[0].bufferIndex = Int(kBufferIndexMeshPositions.rawValue)
        
        // Texture Coordinates.
        imageVertexDescriptor.attributes[1].format = .float2
        imageVertexDescriptor.attributes[1].offset = 8
        imageVertexDescriptor.attributes[0].bufferIndex = Int(kBufferIndexMeshPositions.rawValue)
        
        renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = arTextures.depthTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        
        // Buffer layout
        imageVertexDescriptor.layouts[0].stride = 16
        imageVertexDescriptor.layouts[0].stepRate = 1
        imageVertexDescriptor.layouts[0].stepFunction = .perVertex

        let filterDepthPipelineStateDescriptor = MTLRenderPipelineDescriptor()
        filterDepthPipelineStateDescriptor.label = "MyFilterRenderingPipeline"
        filterDepthPipelineStateDescriptor.sampleCount = 1
        filterDepthPipelineStateDescriptor.vertexFunction = capturedImageVertexFunction
        filterDepthPipelineStateDescriptor.fragmentFunction = filterDepthFragmentFunction
        filterDepthPipelineStateDescriptor.vertexDescriptor = imageVertexDescriptor
        filterDepthPipelineStateDescriptor.colorAttachments[0].pixelFormat = arTextures.depthTexture.pixelFormat
        
        do {
            try renderPipelineState = device.makeRenderPipelineState(descriptor: filterDepthPipelineStateDescriptor)
        } catch let error {
            print ("Failed to created render to target pipeline state, error \(error)")
        }
    }
    
    func filterWithInfo(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.label = "Depth Filtering Render Pass"
        renderEncoder.setCullMode(.none)
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(imagePlaneVertexBuffer, offset: 0, index: Int(kBufferIndexMeshPositions.rawValue))
        renderEncoder.setFragmentTexture(arTextures.rawDepthTexture, index: Int(kTextureIndexRawDepth.rawValue))
        renderEncoder.setFragmentTexture(arTextures.confiTexture, index: Int(kTextureIndexConfidence.rawValue))

        // call drawing primitive
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
    }
}
