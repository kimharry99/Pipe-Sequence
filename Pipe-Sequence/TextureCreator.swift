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

    init(session: ARSession) {
        self.session = session
        // initialize rendering states
        // initialize vertex buffer
        // initialize textures
    }
    
    func create() -> CVMetalTexture? {
        // create RGB CVMetaltexture from YCbCr CVPixelBuffer
        let texture: CVMetalTexture? = nil
        
        guard let currentFrame = session.currentFrame else {
            return texture
        }
        // get Y and CbCr textures from YCbCr pixel buffer
        
        // set render Encoder
        
        // set renderPipelineState
        // set depthStencilState
        // set vertex buffer depends on vertex shader (usually image plane)
        // set fragment texture
        
        // call drawing primitive
        
        return texture
    }
}
