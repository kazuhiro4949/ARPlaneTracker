//  Copyright (c) 2019 Kazuhiro Hayashi
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

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
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

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
    }
    
    func planeTracker(_ planeTracker: ARPlaneTracker, didDetectExtendedPlaneWith hitTestResult: ARHitTestResult, camera: ARCamera?) {
        notdetectAnimation()
    }
    
    func planeTracker(_ planeTracker: ARPlaneTracker, didDetect realWorldPlaneAnchor: ARPlaneAnchor, hitTestResult: ARHitTestResult, camera: ARCamera?) {
        detectAnimation()
    }
    
    func notdetectAnimation() {
        guard !positioningNode.hasActions else { return }
        
        let fadeOutAction = SCNAction.fadeOut(duration: 0.2)
        fadeOutAction.timingMode = .easeInEaseOut
        
        let fadeInAction = SCNAction.fadeIn(duration: 0.2)
        fadeInAction.timingMode = .easeInEaseOut
        
        let sequence = SCNAction.sequence([fadeOutAction, fadeInAction])
        let repeatForever = SCNAction.repeatForever(sequence)
        positioningNode.runAction(repeatForever)
    }
    
    
    func detectAnimation() {
        guard positioningNode.hasActions else { return }
        positioningNode.removeAllActions()

        let fadeInAction = SCNAction.fadeIn(duration: 0.2)
        fadeInAction.timingMode = .easeInEaseOut

        positioningNode.runAction(fadeInAction)
    }
}
