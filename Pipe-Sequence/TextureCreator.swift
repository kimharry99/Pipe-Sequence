//
//  TextureCreator.swift
//  Pipe-Sequence
//
//  Created by Dong-Min KIM on 2022/10/11.
//

import Foundation
import Metal
import MetalKit
import ARKit


class TextureCreator {
    let session: ARSession
    let device: MTLDevice
    let arTextures: ARTextureContainer
    
    // Vertex data for an image plane
    let kImagePlaneVertexData: [Float] = [
        -1.0, -1.0,  0.0, 1.0,
        1.0, -1.0,  1.0, 1.0,
        -1.0,  1.0,  0.0, 0.0,
        1.0,  1.0,  1.0, 0.0,
    ]
    
    // Metal Objects
    var commandQueue: MTLCommandQueue!
    var renderPassDescriptor: MTLRenderPassDescriptor!
    var renderToTargetPipelineState: MTLRenderPipelineState!
    var capturedImageTextureY: CVMetalTexture?
    var capturedImageTextureCbCr: CVMetalTexture?
    var cvDepthTexture: CVMetalTexture?
    var cvConfiTexture: CVMetalTexture?
    var imagePlaneVertexBuffer: MTLBuffer!
    
    // Result Texture
//    var renderResultTexture: MTLTexture!

    // Source Image Texture Cache
    var sourceTextureCache: CVMetalTextureCache!

    init(session: ARSession, device: MTLDevice, arTextures: ARTextureContainer) {
        self.session = session
        self.device = device
        self.arTextures = arTextures
        
        loadMetal()
    }
    
    func create(commandBuffer: MTLCommandBuffer) {
        // create RGB CVMetaltexture from YCbCr CVPixelBuffer
        
        // convert CVPixelBuffer to Metal Texture
        updateARState()
        // set render Encoder
        if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            
            drawCapturedImage(renderEncoder: renderEncoder)
//            makeDepthTexture()
            makeConfiTexture()
            
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
        
        // Load all the shader files with a metal file extension in the project
        let defaultLibrary = device.makeDefaultLibrary()!
        
        let capturedImageVertexFunction = defaultLibrary.makeFunction(name: "capturedImageVertexTransform")!
        let capturedImageFragmentFunction = defaultLibrary.makeFunction(name: "capturedImageFragmentShader")!

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

        // init target texture
//        let texDescriptor = MTLTextureDescriptor()
//        texDescriptor.textureType = .type2D
//        texDescriptor.width = 512
//        texDescriptor.height = 512
//        texDescriptor.pixelFormat = .rgba8Unorm
//        texDescriptor.usage = [.renderTarget, .shaderRead]
        // alternative code
        // texDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)
        
//        renderResultTexture = device.makeTexture(descriptor: texDescriptor)!
        
        // init renderPassDescriptor
        renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = arTextures.colorTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
        renderPassDescriptor.colorAttachments[0].storeAction = .store

        renderPassDescriptor.colorAttachments[1].texture = arTextures.depthTexture
        renderPassDescriptor.colorAttachments[1].loadAction = .clear
        renderPassDescriptor.colorAttachments[1].clearColor = MTLClearColorMake(0, 0, 0, 1)
        renderPassDescriptor.colorAttachments[1].storeAction = .store

        // init RenderPipelineDescriptor
        let renderToTargetPipelineStateDescriptor = MTLRenderPipelineDescriptor()
        renderToTargetPipelineStateDescriptor.label = "MyRenderToTargetPipeline"
        renderToTargetPipelineStateDescriptor.sampleCount = 1
        renderToTargetPipelineStateDescriptor.vertexFunction = capturedImageVertexFunction
        renderToTargetPipelineStateDescriptor.fragmentFunction = capturedImageFragmentFunction
        renderToTargetPipelineStateDescriptor.vertexDescriptor = imageVertexDescriptor
        renderToTargetPipelineStateDescriptor.colorAttachments[0].pixelFormat = arTextures.colorTexture.pixelFormat
        renderToTargetPipelineStateDescriptor.colorAttachments[1].pixelFormat = arTextures.depthTexture.pixelFormat
        
        do {
            try renderToTargetPipelineState = device.makeRenderPipelineState(descriptor: renderToTargetPipelineStateDescriptor)
        } catch let error {
            print ("Failed to created render to target pipeline state, error \(error)")
        }
        
        var textureCache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
        sourceTextureCache = textureCache
    }
    
    func updateARState() {
        guard let currentFrame = session.currentFrame else {
            return
        }
        // Create two textures (Y and CbCr) from the provided frame's captured image
        updateCapturedImageTextures(frame: currentFrame)

        // Prepare the current frame's depth and confidence images for transfer to the GPU.
        updateARDepthTexures(frame: currentFrame)
    }

    // Creates two textures (Y and CbCr) to transfer the current frame's camera image to the GPU for rendering.
    func updateCapturedImageTextures(frame: ARFrame) {
        if CVPixelBufferGetPlaneCount(frame.capturedImage) < 2 {
            return
        }
        capturedImageTextureY = createTexture(fromPixelBuffer: frame.capturedImage, pixelFormat: .r8Unorm, planeIndex: 0)
        capturedImageTextureCbCr = createTexture(fromPixelBuffer: frame.capturedImage, pixelFormat: .rg8Unorm, planeIndex: 1)
    }

    // Assigns an appropriate MTL pixel format given the argument pixel-buffer's format.
    fileprivate func setMTLPixelFormat(_ texturePixelFormat: inout MTLPixelFormat?, basedOn pixelBuffer: CVPixelBuffer!) {
        if CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_DepthFloat32 {
            texturePixelFormat = .r32Float
        } else if CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_OneComponent8 {
            texturePixelFormat = .r8Uint
        } else {
            fatalError("Unsupported ARDepthData pixel-buffer format.")
        }
    }

    // Prepares the scene depth information for transfer to the GPU for rendering.
    func updateARDepthTexures(frame: ARFrame) {
        // Get the scene depth or smoothed scene depth from the current frame.
        guard let sceneDepth = frame.sceneDepth else {
            print("Failed to acquire scene depth.")
            return
        }
        var pixelBuffer: CVPixelBuffer!
        pixelBuffer = sceneDepth.depthMap
        
        // Create a Metal texture from the depth image provided by ARKit.
        var texturePixelFormat: MTLPixelFormat!
        setMTLPixelFormat(&texturePixelFormat, basedOn: pixelBuffer)
        cvDepthTexture = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat: texturePixelFormat, planeIndex: 0)

        // Get the current depth confidence values from the current frame.
        pixelBuffer = sceneDepth.confidenceMap
        setMTLPixelFormat(&texturePixelFormat, basedOn: pixelBuffer)
        cvConfiTexture = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat: texturePixelFormat, planeIndex: 0)
    }

    func createTexture(fromPixelBuffer pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int) -> CVMetalTexture? {
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        
        var texture: CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, sourceTextureCache, pixelBuffer, nil, pixelFormat, width, height, planeIndex, &texture)
        
        if status != kCVReturnSuccess {
            texture = nil
        }
        
        return texture
    }
    
    func drawCapturedImage(renderEncoder: MTLRenderCommandEncoder) {
        guard let textureY = capturedImageTextureY, let textureCbCr = capturedImageTextureCbCr else {
            return
        }

        renderEncoder.label = "RGB Texture Creating Render Pass"
        renderEncoder.setCullMode(.none)
        // set renderPipelineState
        renderEncoder.setRenderPipelineState(renderToTargetPipelineState)
        // set vertex buffer depends on vertex shader (usually image plane)
        renderEncoder.setVertexBuffer(imagePlaneVertexBuffer, offset: 0, index: Int(kBufferIndexMeshPositions.rawValue))
        // set fragment texture
        renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(textureY), index: Int(kTextureIndexY.rawValue))
        renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(textureCbCr), index: Int(kTextureIndexCbCr.rawValue))
        
        // call drawing primitive
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
    }
    
//    func makeDepthTexture(){
//        guard let depthTexture = cvDepthTexture else {
//            return
//        }
//        arTextures.depthTexture = CVMetalTextureGetTexture(depthTexture)
//    }
    
    func makeConfiTexture(){
        guard let confiTexture = cvConfiTexture else {
            return
        }
        arTextures.confiTexture = CVMetalTextureGetTexture(confiTexture)
    }
}
