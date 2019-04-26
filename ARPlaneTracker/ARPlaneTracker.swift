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
import ARKit

public protocol ARPlaneTrackerDelegate: AnyObject {
    func planeTrackerDidInitialize(_ planeTracker: ARPlaneTracker)
    func planeTracker(_ planeTracker: ARPlaneTracker, didDetect horizontalPlaneAnchor: ARPlaneAnchor, hitTestResult: ARHitTestResult, camera: ARCamera?)
    func planeTracker(_ planeTracker: ARPlaneTracker, failToDetectHorizontalAnchorWith hitTestResult: ARHitTestResult, camera: ARCamera?)
}


public class ARPlaneTracker: SCNNode {
    enum AlignmentState {
        case notDetermined
        case changing
        case aligned
    }
    
    public enum State: Equatable {
        case initializing
        case detecting(hitTestResult: ARHitTestResult, camera: ARCamera?)
    }
    
    public private(set) var state: State = .initializing {
        didSet {
            guard state != oldValue else { return }
            
            switch state {
            case .initializing:
                billboard()
                
            case let .detecting(hitTestResult, camera):
                target(hitTestResult, camera)
            }
        }
    }
    
    public func updateTracker() {
        if let camera = sceneView?.session.currentFrame?.camera,
            case .normal = camera.trackingState,
            let result = hitTest() {
            updateQueue.async { [weak self] in
                guard let self = self else { return }
                self.sceneView?.scene.rootNode.addChildNode(self)
                self.state = .detecting(hitTestResult: result, camera: camera)
            }
        } else {
            updateQueue.async { [weak self] in
                guard let self = self else { return }
                self.sceneView?.pointOfView?.addChildNode(self)
                self.state = .initializing
                self.alignmentState = .notDetermined
            }
        }
    }
    
    public private(set) var anchorsOfVisitedPlanes: Set<ARAnchor> = []
    public private(set) var currentPlaneAnchor: ARPlaneAnchor?
    
    public weak var sceneView: ARSCNView?
    public weak var delegate: ARPlaneTrackerDelegate?
    
    private var updateQueue = DispatchQueue(label: "kazuhiro.hayashi.ARPlaneTracker.updateQueue")
    
    private var alignmentState: AlignmentState = .notDetermined
    private var recentTrackerPositions: [float3] = []
    
    
    public override init() {
        super.init()
        opacity = 0
    }
    
    public override func addChildNode(_ child: SCNNode) {
        super.addChildNode(child)
        billboard()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func hide() {
        guard action(forKey: "hide") == nil else { return }
        
        runAction(.fadeOut(duration: 0.5), forKey: "hide")
    }
    
    public func unhide() {
        guard action(forKey: "unhide") == nil else { return }
        
        runAction(.fadeIn(duration: 0.5), forKey: "unhide")
    }
    
    private func billboard() {
        simdTransform = matrix_identity_float4x4
        eulerAngles.x = .pi / 2
        simdPosition = float3(0, 0, -0.8)
        unhide()
        
        delegate?.planeTrackerDidInitialize(self)
    }
    
    private func updateTransform(for position: float3, hitTestResult: ARHitTestResult, camera: ARCamera?) {
        simdPosition = recentTrackerPositions.avarage
        simdScale = float3(repeating: scale(camera: camera))

        if let camera = camera, state != .initializing && alignmentState == .notDetermined {
            align(with: camera)
        }
    }

    private func hitTest() -> ARHitTestResult? {
        guard let sceneView = sceneView else { return nil }
        return sceneView.hitTest(
            sceneView.center,
            types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane]
            ).first
    }
    
    private func align(with camera: ARCamera) {
        let tilt = abs(camera.eulerAngles.x)
        let threshold1: Float = .pi / 2 * 0.65
        let threshold2: Float = .pi / 2 * 0.75
        let yaw = atan2f(camera.transform.columns.0.x, camera.transform.columns.1.x)
        var angle: Float = 0
        
        switch tilt {
        case 0..<threshold1:
            angle = camera.eulerAngles.y
            
        case threshold1..<threshold2:
            let relativeInRange = abs((tilt - threshold1) / (threshold2 - threshold1))
            let normalizedY = normalize(camera.eulerAngles.y, forMinimalRotationTo: yaw)
            angle = normalizedY * (1 - relativeInRange) + yaw * relativeInRange
            
        default:
            angle = yaw
        }
        
        let tempNode = SCNNode()
        tempNode.simdRotation = float4(0, 1, 0, angle)
        animateAlignemnt(to: tempNode.simdOrientation)
    }
    
    private func scale(camera: ARCamera?) -> Float {
        guard let camera = camera else { return 1.0 }
        
        let distanceFromCamera = simd_length(simdWorldPosition - camera.transform.translation)
        if distanceFromCamera < 0.7 {
             return distanceFromCamera / 0.7
        } else {
            return 0.25 * distanceFromCamera + 0.825
        }
    }
    
    private func normalize(_ angle: Float, forMinimalRotationTo ref: Float) -> Float {
        var normalized = angle
        while abs(normalized - ref) > .pi / 4 {
            if angle > ref {
                normalized -= .pi / 2
            } else {
                normalized += .pi / 2
            }
        }
        return normalized
    }
    
    private func animateAlignemnt(to orentation: simd_quatf) {
        alignmentState = .changing
        SCNTransaction.begin()
        SCNTransaction.completionBlock = { [weak self] in
            self?.alignmentState = .aligned
        }
        SCNTransaction.animationDuration = 0.5
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        simdOrientation = orentation
        SCNTransaction.commit()
    }
    
    private func target(_ hitTestResult: ARHitTestResult, _ camera: ARCamera?) {
        if let planeAnchor = hitTestResult.anchor as? ARPlaneAnchor,
            hitTestResult.type == .existingPlaneUsingGeometry,
            planeAnchor.alignment == .horizontal {
            
            delegate?.planeTracker(self, didDetect: planeAnchor, hitTestResult: hitTestResult, camera: camera)
            anchorsOfVisitedPlanes.insert(planeAnchor)
            currentPlaneAnchor = planeAnchor
        } else {
            
            delegate?.planeTracker(self, failToDetectHorizontalAnchorWith: hitTestResult, camera: camera)
            currentPlaneAnchor = nil
        }
        
        let position = hitTestResult.worldTransform.translation
        
        recentTrackerPositions.append(position)
        recentTrackerPositions = Array(recentTrackerPositions.suffix(20))
        
        updateTransform(for: position, hitTestResult: hitTestResult, camera: camera)
    }
}


extension float4x4 {
    var translation: float3 {
        get {
            let translation = columns.3
            return float3(translation.x, translation.y, translation.z)
        }
        set(newValue) {
            columns.3 = float4(newValue.x, newValue.y, newValue.z, columns.3.w)
        }
    }
    
    var orientation: simd_quatf {
        return simd_quaternion(self)
    }
    
    init(uniformScale scale: Float) {
        self = matrix_identity_float4x4
        columns.0.x = scale
        columns.0.y = scale
        columns.0.z = scale
    }
}

extension Array where Element == float3 {
    var avarage: float3 {
        return reduce(float3(repeating: 0), {$0 + $1}) / Float(count)
    }
}
