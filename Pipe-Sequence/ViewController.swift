//
//  ViewController.swift
//  Pipe-Sequence
//
//  Created by Dong-Min KIM on 2022/09/27.
//

import UIKit
import ARKit
import Metal
import MetalKit


extension MTKView: RenderDestinationProvider {
}

class ViewController: UIViewController, MTKViewDelegate, ARSessionDelegate {

    @IBOutlet weak var startRecordingButton: UIButton!

    var session: ARSession!
    var pipeSequenceRecorder: PipeSequenceRecorder!
    var renderer: Renderer!
    var textureCreator: TextureCreator!

    @IBAction func pressStartFusion(_ sender: UIButton) {
        // end recording
        if pipeSequenceRecorder.getIsRecording() {
            self.pipeSequenceRecorder.endRecording()
            startRecordingButton.setTitle("Recording Start", for: .normal)
        }
        // start recording
        else {
            initArSession()
            self.pipeSequenceRecorder.startRecording()
            startRecordingButton.setTitle("Recording End", for: .normal)
        }
    }

    func initArSession() {
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = [.smoothedSceneDepth]
        configuration.worldAlignment = .gravity
        configuration.isAutoFocusEnabled = false

        // Run the view's session
        session.run(configuration)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the view's delegate
        session = ARSession()
        session.delegate = self

        // Set the view to use the default device
        if let view = self.view as? MTKView {
            view.device = MTLCreateSystemDefaultDevice()
            view.backgroundColor = UIColor.clear
            view.delegate = self

            guard view.device != nil else {
                print("Metal is not supported on this device")
                return
            }

            // Configure the recorder to record the sequence
            pipeSequenceRecorder = PipeSequenceRecorder(session: session, device: view.device!, renderDestination: view)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initArSession()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        session.pause()
    }

    // MARK: - MTKViewDelegate

    // Called whenever view changes orientation or layout is changed
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
//        renderer.drawRectResized(size: size)
    }

    // Called whenever the view needs to render
    func draw(in view: MTKView) {
        pipeSequenceRecorder.update()
    }
}
