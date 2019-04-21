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
    
    var focusSquare = FocusSquare()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        sceneView.scene.rootNode.addChildNode(focusSquare)
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
            self.updateFocusSquare()
        }
    }
    
    var updateQueue = DispatchQueue(label: "label")
    
    func updateFocusSquare() {
        if let camera = sceneView.session.currentFrame?.camera,
            case .normal = camera.trackingState, let result = sceneView.smartCenterHitTest() {
            updateQueue.async {
                self.focusSquare.state = .detecting(hitTestResult: result, camera: camera)
            }
        } else {
            updateQueue.async {
                self.focusSquare.state = .initializing
            }
        }
    }
}
