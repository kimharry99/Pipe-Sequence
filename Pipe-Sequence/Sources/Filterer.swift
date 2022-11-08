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
        let defaultLibrary = device.makeDefaultLibrary()!
        
        let capturedImageVertexFunction = defaultLibrary.makeFunction(name: "capturedImageVertexTransform")!
        let filterDepthFragmentFunction = defaultLibrary.makeFunction(name: "filterDepthFragmentShader")!

        let filterDepthPipelineStateDescriptor = MTLRenderPipelineDescriptor()
        filterDepthPipelineStateDescriptor.label = "MyFilterRenderingPipeline"
        filterDepthPipelineStateDescriptor.sampleCount = 1
        filterDepthPipelineStateDescriptor.vertexFunction = capturedImageVertexFunction
        filterDepthPipelineStateDescriptor.fragmentFunction = filterDepthFragmentFunction

        renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = arTextures.depthTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        
    }
    
    func filterWithInfo(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.label = "Depth Filtering Render Pass"
        renderEncoder.setCullMode(.none)
//        renderEncoder.setRenderPipelineState(<#T##pipelineState: MTLRenderPipelineState##MTLRenderPipelineState#>)
        renderEncoder.setFragmentTexture(arTextures.rawDepthTexture, index: Int(kTextureIndexDepth.rawValue))
    }
}
