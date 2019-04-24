//
//  ViewController.swift
//  iOS Sample
//
//  Created by Kazuhiro Hayashi on 2019/04/21.
//  Copyright © 2019 Kazuhiro Hayashi. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import ARPlaneTracker

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    let arPlaneTracker = ARPlaneTracker()
    let positioningNode = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        let plane = SCNPlane(width: 0.1, height: 0.1)
        plane.firstMaterial?.diffuse.contents = UIImage(named: "Image")
        plane.firstMaterial?.isDoubleSided = true
        
        positioningNode.geometry = plane
        positioningNode.eulerAngles.x = .pi / 2
        
        
        arPlaneTracker.addChildNode(positioningNode)
        arPlaneTracker.sceneView = sceneView
        arPlaneTracker.delegate = self
        sceneView.scene.rootNode.addChildNode(arPlaneTracker)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
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
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.arPlaneTracker.updateTracker()
        }
    }
}


extension ViewController: ARPlaneTrackerDelegate {
    func planeTrackerDidInitialize(_ planeTracker: ARPlaneTracker) {
//        positioningNode.performOpenAnimation()
    }
    
    func planeTracker(_ planeTracker: ARPlaneTracker, didDetectExtendedPlaneWith hitTestResult: ARHitTestResult, camera: ARCamera?) {
//        positioningNode.performOpenAnimation()
    }
    
    func planeTracker(_ planeTracker: ARPlaneTracker, didDetect realWorldPlaneAnchor: ARPlaneAnchor, hitTestResult: ARHitTestResult, camera: ARCamera?) {
//        positioningNode.performCloseAnimation()
    }
}
