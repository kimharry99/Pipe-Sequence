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
    var rawDepthTexture: MTLTexture?
    var rawSmoothDepthTexture: MTLTexture?
    var confiTexture: MTLTexture?
    var smoothConfiTexture: MTLTexture?
    var depthTexture: MTLTexture
    var smoothDepthTexture: MTLTexture
    var valid: Bool

    init(device: MTLDevice) {
        // init target texture
        let texDescriptor = MTLTextureDescriptor()
        texDescriptor.textureType = .type2D
        texDescriptor.width = 512
        texDescriptor.height = 384
        texDescriptor.pixelFormat = .rgba8Unorm
        texDescriptor.usage = [.renderTarget, .shaderRead]
        // alternative code
        // texDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)
        colorTexture = device.makeTexture(descriptor: texDescriptor)!

        // initialize depth texture
        texDescriptor.width = 256
        texDescriptor.height = 192
        texDescriptor.pixelFormat = .r16Uint
        texDescriptor.usage = [.renderTarget, .shaderRead]
        depthTexture = device.makeTexture(descriptor: texDescriptor)!
        smoothDepthTexture = device.makeTexture(descriptor: texDescriptor)!

        valid = false
    }
}

class PipeSequenceRecorder {
    var textureCreator: TextureCreator
    var renderer: Renderer
    var filterer: Filterer
    var dataRecorder: DataRecorder
    
    let commandQueue: MTLCommandQueue!
    
    let arTextures: ARTextureContainer

    private var isRecording: Bool = false
    open func getIsRecording() -> Bool {return isRecording}
    
    init(session: ARSession, device: MTLDevice, renderDestination: RenderDestinationProvider){
        self.arTextures = ARTextureContainer(device: device)
        self.textureCreator = TextureCreator(session: session, device: device, arTextures: arTextures)
        self.renderer = Renderer(session: session, device: device, renderDestination: renderDestination, arTextures: arTextures)
        self.filterer = Filterer(device: device, arTextures: arTextures)
        self.dataRecorder = DataRecorder(session: session, arTextures: arTextures)
        
        // init metal objects
        commandQueue = device.makeCommandQueue()
    }
    
    func endRecording(){
        self.isRecording = false
    }

    func startRecording(){
        self.dataRecorder.createFiles()
        self.isRecording = true
    }
    
    func update() {
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            commandBuffer.label = "MyCommand"

            arTextures.valid = true
            var textures = [textureCreator.capturedImageTextureY, textureCreator.capturedImageTextureCbCr, textureCreator.cvDepthTexture, textureCreator.cvConfiTexture, textureCreator.cvSmoothDepthTexture, textureCreator.cvSmoothConfiTexture]
            commandBuffer.addCompletedHandler { [weak self] commandBuffer in
                if let strongSelf = self {
                    if strongSelf.getIsRecording() {
                        strongSelf.dataRecorder.save()
                    }
                }
                textures.removeAll()
            }
            // create MTLTexture from captured image from ARSession
            textureCreator.create(commandBuffer: commandBuffer)
            // filter depth data with confidence
            filterer.filter(commandBuffer: commandBuffer)
            // render source texture to main view
            renderer.update(commandBuffer: commandBuffer)
            
            commandBuffer.commit()
        }
    }
}
