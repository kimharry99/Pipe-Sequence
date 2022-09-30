//
//  ViewController.swift
//  Pipe-Sequence
//
//  Created by Dong-Min KIM on 2022/09/27.
//

import UIKit
import SceneKit
import ARKit

//- Tag: ARData
// Store depth-related AR data.
final class ARData {
    var timestamp: Double?
    var depthImage: CVPixelBuffer?
    var depthSmoothImage: CVPixelBuffer?
    var colorImage: CVPixelBuffer?
    var confidenceImage: CVPixelBuffer?
    var confidenceSmoothImage: CVPixelBuffer?
    var cameraIntrinsics = simd_float3x3()
    var cameraResolution = CGSize()
}

class ViewController: UIViewController, ARSessionDelegate, ARSCNViewDelegate, SCNSceneRendererDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var renderer: SCNRenderer!
    
    var arData = ARData()
    
    // Set the original depth size.
    let origDepthWidth = 256
    let origDepthHeight = 192
    
    var offscreenTexture: MTLTexture!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMetal()
        setupTexture()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()

        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .sceneDepth
        configuration.worldAlignment = .gravity
        configuration.isAutoFocusEnabled = false
        configuration.planeDetection = [.horizontal, .vertical]

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // Send required data from `ARFrame` to the delegate class via the `onNewARData` callback.
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
      if(frame.sceneDepth != nil) && (frame.smoothedSceneDepth != nil) {
          arData.timestamp = frame.timestamp
          arData.depthImage = frame.sceneDepth?.depthMap
          arData.depthSmoothImage = frame.smoothedSceneDepth?.depthMap
          arData.confidenceImage = frame.sceneDepth?.confidenceMap
          arData.confidenceSmoothImage = frame.smoothedSceneDepth?.confidenceMap
          arData.colorImage = frame.capturedImage
          arData.cameraIntrinsics = frame.camera.intrinsics
          arData.cameraResolution = frame.camera.imageResolution
      }
    }

    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Place content only for anchors found by plane detection.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Create a custom object to visualize the plane geometry and extent.
        let plane = Plane(anchor: planeAnchor, in: sceneView)
        
        // Add the visualization to the ARKit-managed node so that it tracks
        // changes in the plane anchor as plane estimation continues.
        node.addChildNode(plane)
    }
    
    /// - Tag: UpdateARContent
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Update only anchors and nodes set up by `renderer(_:didAdd:for:)`.
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let plane = node.childNodes.first as? Plane
            else { return }

        // Update ARSCNPlaneGeometry to the anchor's new estimated shape.
        if let planeGeometry = plane.meshNode.geometry as? ARSCNPlaneGeometry {
            planeGeometry.update(from: planeAnchor.geometry)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    // MARK: SCNSceneRendererDelegate
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        doRender()
        let pngData = UIImage(texture: offscreenTexture).pngData()
        var url = URL(fileURLWithPath: NSTemporaryDirectory())
//        url.appendPathComponent(String(format: "%.0f.png", Float(arData.timestamp!)))
        url.appendPathComponent(String(format: "1.png"))
        try? pngData?.write(to: url)
    }
    
    // MARK: - Private methods
    func setupMetal() {
        if let defaultMtlDevice = MTLCreateSystemDefaultDevice() {
            device = defaultMtlDevice
            commandQueue = device.makeCommandQueue()
            renderer = SCNRenderer(device: device, options: nil)
        } else {
            fatalError("iOS simulator does not support Metal, this example can only be run on a real device.")
        }
    }
    
    func setupTexture(){
        let textureUsage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)
        let texture = createTexture(metalDevice: device, width: origDepthWidth, height: origDepthHeight, usage: textureUsage, pixelFormat: MTLPixelFormat.rgba8Unorm)
        
        offscreenTexture = texture
    }

    func createTexture(metalDevice: MTLDevice, width: Int, height: Int, usage: MTLTextureUsage, pixelFormat: MTLPixelFormat) -> MTLTexture {
        let descriptor: MTLTextureDescriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = pixelFormat
        descriptor.width = width
        descriptor.height = height
        descriptor.usage = usage
        let resTexture = metalDevice.makeTexture(descriptor: descriptor)
        return resTexture!
    }

    func doRender(){
        //rendering to a MTLTexture, so the viewport is the size of this texture
        let viewport = CGRect(x: 0, y: 0, width: CGFloat(origDepthWidth), height: CGFloat(origDepthHeight))
        
        //write to offscreenTexture, clear the texture before rendering using green, store the result
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = offscreenTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 1, 0, 1.0); //green
        renderPassDescriptor.colorAttachments[0].storeAction = .store

        let commandBuffer = commandQueue.makeCommandBuffer()!
        
        // use scene and camera pose
        renderer.scene = sceneView.scene
        renderer.pointOfView = sceneView.pointOfView
        renderer.render(atTime: 0, viewport: viewport, commandBuffer: commandBuffer, passDescriptor: renderPassDescriptor)
        
        commandBuffer.commit()
    }
}
