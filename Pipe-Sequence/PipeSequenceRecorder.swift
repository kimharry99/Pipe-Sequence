//
//  PipeSequenceRecorder.swift
//  Pipe-Sequence
//
//  Created by Dong-Min Kim on 2022/10/12.
//

import Foundation
import ARKit

class ARTextureContainer {
    var colorTexture: MTLTexture
    var depthTexture: MTLTexture?
    var confiTexture: MTLTexture?
    var valid: Bool
    
    init(device: MTLDevice) {
        // init target texture
        let texDescriptor = MTLTextureDescriptor()
        texDescriptor.textureType = .type2D
        texDescriptor.width = 256
        texDescriptor.height = 192
        texDescriptor.pixelFormat = .rgba8Unorm
        texDescriptor.usage = [.renderTarget, .shaderRead]
        // alternative code
        // texDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)
        colorTexture = device.makeTexture(descriptor: texDescriptor)!

        valid = false
    }
}

class PipeSequenceRecorder {
    var textureCreator: TextureCreator
    var renderer: Renderer
    
    let commandQueue: MTLCommandQueue!
    
    let arTextures: ARTextureContainer
    
    init(session: ARSession, device: MTLDevice, renderDestination: RenderDestinationProvider){
        self.arTextures = ARTextureContainer(device: device)
        self.textureCreator = TextureCreator(session: session, device: device, arTextures: arTextures)
        self.renderer = Renderer(session: session, device: device, renderDestination: renderDestination)

        // set capture image texture to renderer as source texture
        // renderer.sourceTexture = textureCreator.renderResultTexture
        
        // init metal objects
        commandQueue = device.makeCommandQueue()
    }
    
    func update() {
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            commandBuffer.label = "MyCommand"

            var textures = [arTextures.colorTexture]
            commandBuffer.addCompletedHandler { commandBuffer in
                textures.removeAll()
            }
            // create MTLTexture from captured image from ARSession
            textureCreator.create(commandBuffer: commandBuffer)
            // render source texture to main view
//            renderer.update()
            
            commandBuffer.commit()
        }
    }
}
