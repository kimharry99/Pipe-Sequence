/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience class for visualizing Plane extent and geometry
*/

import ARKit

// Convenience extension for colors defined in asset catalog.
extension UIColor {
    static let planeColor = UIColor(named: "planeColor")!
}

class Plane: SCNNode {
    
    let meshNode: SCNNode
    
    /// - Tag: VisualizePlane
    init(anchor: ARPlaneAnchor, in sceneView: ARSCNView) {
        
        #if targetEnvironment(simulator)
        #error("ARKit is not supported in iOS Simulator. Connect a physical iOS device and select it as your Xcode run destination, or select Generic iOS Device as a build-only destination.")
        #else

        // Create a mesh to visualize the estimated shape of the plane.
        guard let meshGeometry = ARSCNPlaneGeometry(device: sceneView.device!)
            else { fatalError("Can't create plane geometry") }
        meshGeometry.update(from: anchor.geometry)
        meshNode = SCNNode(geometry: meshGeometry)

        super.init()

        self.setupMeshVisualStyle()

        // Add the plane extent and plane geometry as child nodes so they appear in the scene.
        addChildNode(meshNode)
        #endif
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupMeshVisualStyle() {
        // Make the plane visualization semitransparent to clearly show real-world placement.
        meshNode.opacity = 1.0
        
        // Use color and blend mode to make planes stand out.
        guard let material = meshNode.geometry?.firstMaterial
            else { fatalError("ARSCNPlaneGeometry always has one material") }
        material.diffuse.contents = UIColor.planeColor
    }
}
