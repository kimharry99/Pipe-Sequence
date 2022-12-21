//
//  DataRecorder.swift
//  Pipe-Sequence
//
//  Created by Dong-Min Kim on 2022/11/02.
//

import os
import Foundation
import ARKit

class DataRecorder {
    let session: ARSession
    let arTextures: ARTextureContainer

    var isCalibrated = false
    // constants for collecting data
    let mulSecondToNanoSecond: Double = 1000000000
    let numDirs = 5
    let DIR_INTRINSC = 0
    let DIR_CAMERA_POSE = 1
    let DIR_RGB_IMAGE = 2
    let DIR_DEPTH_IMAGE = 3
    let DIR_SMOOTH_DEPTH_IMAGE = 4
    
    // text directory
    var dirURLs = [URL]()
    var dirNames: [String] = ["intrinsic", "pose", "color", "depth", "smooth"]
    
    init(session: ARSession, arTextures: ARTextureContainer) {
        self.session = session
        self.arTextures = arTextures
        
        createFiles()
    }
    
    func save(){
        guard let currentFrame = session.currentFrame else {
            return
        }
        // if arTextures.valid == false {
        //     return
        // }
        DispatchQueue.global(qos: .userInitiated).async {
            // camera intrinsic save
            if self.isCalibrated == false {
                self.saveIntrinsic(frame: currentFrame)
                self.isCalibrated = true
            }
            // color image save
            self.saveColorImage(frame: currentFrame)
            // depth image save
            self.saveDepthImage(frame: currentFrame)
            // save smooth depth image
            self.saveSmoothDepthImage(frame: currentFrame)
            // camera pose save
            self.saveCameraPose(frame: currentFrame)
        }
    }
    
    // MARK: - Private
    func createFiles()
    {
        // initialize file handlers
        self.dirURLs.removeAll()
        
        // create ARKit result directory
        let timeHeader = "# Created at \(timeToString()) \n"
        let dataName = timeToString()
        var urlBase = URL(fileURLWithPath: NSTemporaryDirectory())
        urlBase.appendPathComponent(dataName)
        // delete previous directories
        if (FileManager.default.fileExists(atPath: urlBase.path)) {
            do {
                try FileManager.default.removeItem(at: urlBase)
            } catch {
                os_log("cannot remove previous file", log:.default, type:.error)
                return
            }
        }
        // create new direcotries
        do {
            try FileManager.default.createDirectory(atPath: urlBase.path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print(error.localizedDescription)
            return
        }
        
        for i in 0...(self.numDirs - 1) {
            var url = URL(fileURLWithPath: NSTemporaryDirectory())
            url.appendPathComponent(dataName)
            url.appendPathComponent(self.dirNames[i])
            self.dirURLs.append(url)
            
            // delete previous directories
            if (FileManager.default.fileExists(atPath: url.path)) {
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    os_log("cannot remove previous file", log:.default, type:.error)
                    return
                }
            }
            
            // create new direcotries
            do {
                try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
                return
            }
            
            // create time information files
            if i == DIR_INTRINSC {
                url.appendPathComponent("time_information.txt")
                if (!FileManager.default.createFile(atPath: url.path, contents: timeHeader.data(using: String.Encoding.utf8), attributes: nil)) {
                    return
                }
            }
        }
        
        print("file creation complete!")
    }

    func saveColorImage(frame: ARFrame) {
        let nTimestamp = frame.timestamp * self.mulSecondToNanoSecond
        // save rgb images
        let pngImage = UIImage(texture: arTextures.colorTexture).pngData()
        var url = self.dirURLs[self.DIR_RGB_IMAGE]
        url.appendPathComponent(String(format: "%.0f.png", nTimestamp))
        try? pngImage?.write(to: url)
    }
    
    func saveDepthImage(frame: ARFrame) {
        let nTimestamp = frame.timestamp * self.mulSecondToNanoSecond
        // save image
        let pngImage = UIImage(texture: arTextures.depthTexture).pngData()
        var url = self.dirURLs[self.DIR_DEPTH_IMAGE]
        url.appendPathComponent(String(format: "%.0f.png", nTimestamp))
        try? pngImage?.write(to: url)
    }

    func saveSmoothDepthImage(frame: ARFrame) {
        let nTimestamp = frame.timestamp * self.mulSecondToNanoSecond
        // save image
        let pngImage = UIImage(texture: arTextures.smoothDepthTexture).pngData()
        var url = self.dirURLs[self.DIR_SMOOTH_DEPTH_IMAGE]
        url.appendPathComponent(String(format: "%.0f.png", nTimestamp))
        try? pngImage?.write(to: url)
    }

    func saveCameraPose(frame: ARFrame) {
        // save camera pose of the frame
        let viewMatrix = frame.camera.transform
        let timestamp = frame.timestamp * self.mulSecondToNanoSecond
        let r_11 = viewMatrix.columns.0.x
        let r_12 = viewMatrix.columns.1.x
        let r_13 = viewMatrix.columns.2.x
        
        let r_21 = viewMatrix.columns.0.y
        let r_22 = viewMatrix.columns.1.y
        let r_23 = viewMatrix.columns.2.y
        
        let r_31 = viewMatrix.columns.0.z
        let r_32 = viewMatrix.columns.1.z
        let r_33 = viewMatrix.columns.2.z
        
        let t_x = viewMatrix.columns.3.x
        let t_y = viewMatrix.columns.3.y
        let t_z = viewMatrix.columns.3.z

        var url = self.dirURLs[self.DIR_CAMERA_POSE]
        url.appendPathComponent(String(format: "%.0f.txt", timestamp))
        let ARKitPoseData = String(format: "%.6f %.6f %.6f %.6f\n%.6f %.6f %.6f %.6f\n%.6f %.6f %.6f %.6f\n",
                                   r_11, r_12, r_13, t_x,
                                   r_21, r_22, r_23, t_y,
                                   r_31, r_32, r_33, t_z)
                                
        if (!FileManager.default.createFile(atPath: url.path, contents: ARKitPoseData.data(using: String.Encoding.utf8), attributes: nil)) {
            os_log("Failed to create file", log: OSLog.default, type: .fault)
        }
    }

    func saveIntrinsic(frame: ARFrame) {
        let intrinsic = frame.camera.intrinsics
        // fx, fy, cx, cy
        let fx = intrinsic.columns.0.x
        let fy = intrinsic.columns.1.y
        let cx = intrinsic.columns.2.x
        let cy = intrinsic.columns.2.y

        var url = self.dirURLs[self.DIR_INTRINSC]
        url.appendPathComponent(String("camera_intrinsic.txt"))
        let intrinsicData = String(format: "%.6f %.6f %.6f %.6f \n",
                                   fx, fy, cx, cy)
                                
        if (!FileManager.default.createFile(atPath: url.path, contents: intrinsicData.data(using: String.Encoding.utf8), attributes: nil)) {
            os_log("Failed to create file", log: OSLog.default, type: .fault)
        }
    }
}
