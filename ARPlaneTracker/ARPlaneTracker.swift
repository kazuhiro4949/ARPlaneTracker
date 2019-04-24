//
//  ARPlaneTradker.swift
//  ARPlaneTracker
//
//  Created by Kazuhiro Hayashi on 2019/03/30.
//  Copyright © 2019 Kazuhiro Hayashi. All rights reserved.
//

import UIKit
import ARKit

public protocol ARPlaneTrackerDelegate: AnyObject {
    func planeTrackerDidInitialize(_ planeTracker: ARPlaneTracker)
    func planeTracker(_ planeTracker: ARPlaneTracker, didDetect realWorldPlaneAnchor: ARPlaneAnchor, hitTestResult: ARHitTestResult, camera: ARCamera?)
    func planeTracker(_ planeTracker: ARPlaneTracker, didDetectExtendedPlaneWith hitTestResult: ARHitTestResult, camera: ARCamera?)
}


public class ARPlaneTracker: SCNNode {
    public enum State: Equatable {
        case initializing
        case detecting(hitTestResult: ARHitTestResult, camera: ARCamera?)
    }
    
    public var lastPosition: float3? {
        switch state {
        case .initializing: return nil
        case let .detecting(hitTestResult, _): return hitTestResult.worldTransform.translation
        }
    }
    
    public var state: State = .initializing {
        didSet {
            guard state != oldValue else { return }
            
            switch state {
            case .initializing:
                billboard()
                
            case let .detecting(hitTestResult, camera):
                if let planeAnchor = hitTestResult.anchor as? ARPlaneAnchor {
                    delegate?.planeTracker(self, didDetect: planeAnchor, hitTestResult: hitTestResult, camera: camera)
                    anchorsOfVisitedPlanes.insert(planeAnchor)
                    currentPlaneAnchor = planeAnchor
                } else {
                    delegate?.planeTracker(self, didDetectExtendedPlaneWith: hitTestResult, camera: camera)
                    currentPlaneAnchor = nil
                }
                
                let position = hitTestResult.worldTransform.translation
                recentTrackerPositions.append(position)
                updateTransform(for: position, hitTestResult: hitTestResult, camera: camera)
            }
        }
    }

    private var updateQueue = DispatchQueue(label: "label")
    
    public func updateTracker() {
        if let camera = sceneView?.session.currentFrame?.camera,
            case .normal = camera.trackingState, let result = sceneView?.smartCenterHitTest() {
            updateQueue.async {
                self.sceneView?.scene.rootNode.addChildNode(self)
                self.state = .detecting(hitTestResult: result, camera: camera)
            }
        } else {
            updateQueue.async {
                self.sceneView?.pointOfView?.addChildNode(self)
                self.state = .initializing
            }
        }
    }
    
    private var isChangingAlignment = false
    private var currentAlignment: ARPlaneAnchor.Alignment?
    private(set) var currentPlaneAnchor: ARPlaneAnchor?
    private var recentTrackerPositions: [float3] = []
    private(set) var recentTrackerAlignment: [ARPlaneAnchor.Alignment] = []
    private var anchorsOfVisitedPlanes: Set<ARAnchor> = []
    
    public weak var sceneView: ARSCNView?
    public weak var delegate: ARPlaneTrackerDelegate?
    
    
    public override init() {
        super.init()
        opacity = 0
    }
    
    public override func addChildNode(_ child: SCNNode) {
        super.addChildNode(child)
        displayNodeHierarchyOnTop(true)
        billboard()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func displayNodeHierarchyOnTop(_ isOnTop: Bool) {
        func updateRenderOrder(for node: SCNNode) {
            node.renderingOrder = isOnTop ? 2 : 0

            for material in node.geometry?.materials ?? [] {
                material.readsFromDepthBuffer = !isOnTop
            }

            for child in node.childNodes {
                updateRenderOrder(for: child)
            }
        }

        updateRenderOrder(for: self)
    }
    
    private func billboard() {
        simdTransform = matrix_identity_float4x4
        eulerAngles.x = .pi / 2
        simdPosition = float3(0, 0, -0.8)
        unhide()
        
        delegate?.planeTrackerDidInitialize(self)
    }
    
    public func hide() {
        guard action(forKey: "hide") == nil else { return }
        
        displayNodeHierarchyOnTop(false)
        runAction(.fadeOut(duration: 0.5), forKey: "hide")
    }
    
    public func unhide() {
        guard action(forKey: "unhide") == nil else { return }
        
        displayNodeHierarchyOnTop(true)
        runAction(.fadeIn(duration: 0.5), forKey: "unhide")
    }

    
    private func updateTransform(for position: float3, hitTestResult: ARHitTestResult, camera: ARCamera?) {
        recentTrackerPositions = Array(recentTrackerPositions.suffix(20))
        
        let average = recentTrackerPositions.reduce(float3(repeating: 0), {$0 + $1}) / Float(recentTrackerPositions.count)
        simdPosition = average
        simdScale = float3(repeating: scaleBasedOnDistance(camera: camera))
        
        guard let camera = camera else { return }
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

        if state != .initializing {
            updateAlignment(for: hitTestResult, yRotationAngle: angle)
        }
    }
    
    private func updateAlignment(for hitTestResult: ARHitTestResult, yRotationAngle angle: Float) {
        if isChangingAlignment {
            return
        }
        
        var shouldAnimateAlignmentChange = false
        
        let tempNode = SCNNode()
        tempNode.simdRotation = float4(0, 1, 0, angle)
        
        var alignment: ARPlaneAnchor.Alignment?
        
        if let planeAnchor = hitTestResult.anchor as? ARPlaneAnchor {
            alignment = planeAnchor.alignment
        } else if hitTestResult.type == .estimatedHorizontalPlane {
            alignment = .horizontal
        } else if hitTestResult.type == .estimatedVerticalPlane {
            alignment = .vertical
        }
        
        if alignment != nil {
            recentTrackerAlignment.append(alignment!)
        }
        
        recentTrackerAlignment = Array(recentTrackerAlignment.suffix(20))
        let horizontalHistory = recentTrackerAlignment.filter({ $0 == .horizontal}).count
        let verticalHistory = recentTrackerAlignment.filter({ $0 == .vertical}).count
    
        if alignment == .horizontal && horizontalHistory > 15 ||
            alignment == .vertical && verticalHistory > 10 ||
            hitTestResult.anchor is ARPlaneAnchor {
            if alignment != currentAlignment {
                shouldAnimateAlignmentChange = true
                currentAlignment = alignment
                recentTrackerAlignment.removeAll()
            }
        } else {
            alignment = currentAlignment
            return
        }
        
        if alignment == .vertical {
            tempNode.simdOrientation = hitTestResult.worldTransform.orientation
            shouldAnimateAlignmentChange = true
        }
        
        if shouldAnimateAlignmentChange {
            performAlignmentAnimation(to: tempNode.simdOrientation)
        } else {
            simdOrientation = tempNode.simdOrientation
        }
    }
    
    private func scaleBasedOnDistance(camera: ARCamera?) -> Float {
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
    
    private func performAlignmentAnimation(to newOrientation: simd_quatf) {
        isChangingAlignment = true
        SCNTransaction.begin()
        SCNTransaction.completionBlock = {
            self.isChangingAlignment = false
        }
        SCNTransaction.animationDuration = 0.5
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        simdOrientation = newOrientation
        SCNTransaction.commit()
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
