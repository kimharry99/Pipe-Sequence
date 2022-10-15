//
//  PipeSequenceRecorder.swift
//  Pipe-Sequence
//
//  Created by Dong-Min Kim on 2022/10/12.
//

import Foundation
import ARKit

class PipeSequenceRecorder {
    var textureCreator: TextureCreator
    var renderer: Renderer
    
    let commandQueue: MTLCommandQueue!
    
    init(session: ARSession, device: MTLDevice, renderDestination: RenderDestinationProvider){
        self.textureCreator = TextureCreator(session: session, device: device)
        self.renderer = Renderer(session: session, device: device, renderDestination: renderDestination)

        // set capture image texture to renderer as source texture
        renderer.sourceTexture = textureCreator.renderResultTexture
        
        // init metal objects
        commandQueue = device.makeCommandQueue()
    }
    
    func update() {
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            commandBuffer.label = "MyCommand"

            var textures = [renderer.sourceTexture]
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
