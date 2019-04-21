//
//  FocusSquare.swift
//  AR3DMeasure
//
//  Created by Kazuhiro Hayashi on 2019/03/30.
//  Copyright © 2019 Kazuhiro Hayashi. All rights reserved.
//

import UIKit
import ARKit

@objc
public class FocusSquare: SCNNode {
    public enum State: Equatable {
        case initializing
        case detecting(hitTestResult: ARHitTestResult, camera: ARCamera?)
    }
    
    static let size: Float = 0.17
    static let thickness: Float = 0.018
    static let scaleForClosedSquare: Float = 0.97
    static let sideLengthForOpenSegments: Float = 0.2
    
    static let animationDuration = 0.7
    
    static let primaryColor = #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1)
    static let fillColor = #colorLiteral(red: 1, green: 0.9254901961, blue: 0.4117647059, alpha: 1)
    
    
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
                displayAsBillboard()
                
            case let .detecting(hitTestResult, camera):
                if let planeAnchor = hitTestResult.anchor as? ARPlaneAnchor {
                    displayAsClose(for: hitTestResult, planeAnchor: planeAnchor, camera: camera)
                    currentPlaneAnchor = planeAnchor
                } else {
                    displayAsOpen(for: hitTestResult, camera: camera)
                    currentPlaneAnchor = nil
                }
            }
        }
    }

    private var isOpen = false
    private var isAnimating = false
    private var isChangingAlignment = false
    private var currentAlignment: ARPlaneAnchor.Alignment?
    
    private(set) var currentPlaneAnchor: ARPlaneAnchor?
    private var recentFocusSquarePositions: [float3] = []
    private(set) var recentFocusSquareAlignment: [ARPlaneAnchor.Alignment] = []
    
    private var anchorsOfVisitedPlanes: Set<ARAnchor> = []
    private var segments: [FocusSquare.Segment] = []
    
    private let positioningNode = SCNNode()
    
    private lazy var fillPlane: SCNNode = {
       let correctionFactor = FocusSquare.thickness / 2
        let length = CGFloat(1.0 - FocusSquare.thickness * 2 + correctionFactor)
        
        let plane = SCNPlane(width: length, height: length)
        let node = SCNNode(geometry: plane)
        node.name = "fillPlane"
        node.opacity = 0
        
        let material = plane.firstMaterial!
        material.diffuse.contents = FocusSquare.fillColor
        material.isDoubleSided = true
        material.ambient.contents = UIColor.black
        material.lightingModel = .constant
        material.emission.contents = FocusSquare.fillColor
        
        return node
    }()
    
    public override init() {
        super.init()
        opacity = 0
        
        let s1 = Segment(name: "s1", corner: .topLeft, alignment: .horizontal)
        let s2 = Segment(name: "s2", corner: .topRight, alignment: .horizontal)
        let s3 = Segment(name: "s3", corner: .topLeft, alignment: .vertical)
        let s4 = Segment(name: "s4", corner: .topRight, alignment: .vertical)
        let s5 = Segment(name: "s5", corner: .bottomLeft, alignment: .vertical)
        let s6 = Segment(name: "s6", corner: .bottomRight, alignment: .vertical)
        let s7 = Segment(name: "s7", corner: .bottomLeft, alignment: .horizontal)
        let s8 = Segment(name: "s8", corner: .bottomRight, alignment: .horizontal)
        segments = [s1, s2, s3, s4, s5, s6, s7, s8]
        
        let sl: Float = 0.5
        let c: Float = FocusSquare.thickness / 2
        s1.simdPosition += float3(-(sl / 2 - c), -(sl - c), 0)
        s2.simdPosition += float3((sl / 2 - c), -(sl - c), 0)
        s3.simdPosition += float3(-sl, -sl / 2, 0)
        s4.simdPosition += float3(sl, -sl / 2, 0)
        s5.simdPosition += float3(-sl, sl / 2, 0)
        s6.simdPosition += float3(sl, sl / 2, 0)
        s7.simdPosition += float3(-(sl / 2 - c), sl - c, 0)
        s8.simdPosition += float3(sl / 2 - c, sl - c, 0)
        
        positioningNode.eulerAngles.x = .pi / 2
        positioningNode.simdScale = float3(FocusSquare.size * FocusSquare.scaleForClosedSquare)
        for segment in segments {
            positioningNode.addChildNode(segment)
        }
        positioningNode.addChildNode(fillPlane)
        
        displayNodeHierarchyOnTop(true)
        
        addChildNode(positioningNode)
        
        displayAsBillboard()
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
        
        updateRenderOrder(for: positioningNode)
    }
    
    private func displayAsBillboard() {
        simdTransform = matrix_identity_float4x4
        eulerAngles.x = .pi / 2
        simdPosition = float3(0, 0, -0.8)
        unhide()
        performOpenAnimation()
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
    
    private func performOpenAnimation() {
        guard !isOpen, !isAnimating else { return }
        isOpen = true
        isAnimating = true
        
        SCNTransaction.begin()
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        SCNTransaction.animationDuration = FocusSquare.animationDuration / 4
        positioningNode.opacity = 1.0
        for segment in segments {
            segment.open()
        }
        SCNTransaction.completionBlock = {
            self.positioningNode.runAction(pulseAction(), forKey: "pulse")
            self.isAnimating = false
        }
        SCNTransaction.commit()
        
        SCNTransaction.begin()
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        SCNTransaction.animationDuration = FocusSquare.animationDuration / 4
        positioningNode.simdScale = float3(FocusSquare.size)
        SCNTransaction.commit()
    }
    
    private func performCloseAnimation(flash: Bool = false) {
        guard isOpen, !isAnimating else { return }
        isOpen = false
        isAnimating = true
        
        positioningNode.removeAction(forKey: "pulse")
        positioningNode.opacity = 1.0
        
        SCNTransaction.begin()
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        SCNTransaction.animationDuration = FocusSquare.animationDuration / 2
        positioningNode.opacity = 0.99
        SCNTransaction.completionBlock = {
            SCNTransaction.begin()
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
            SCNTransaction.animationDuration = FocusSquare.animationDuration / 4
            for segment in self.segments {
                segment.close()
            }
            SCNTransaction.completionBlock = { self.isAnimating = false }
            SCNTransaction.commit()
        }
        SCNTransaction.commit()
        
        positioningNode.addAnimation(scaleAnimation(for: "transform.scale.x"), forKey: "transfirm.scale.x")
        positioningNode.addAnimation(scaleAnimation(for: "transform.scale.y"), forKey: "transfirm.scale.y")
        positioningNode.addAnimation(scaleAnimation(for: "transform.scale.z"), forKey: "transfirm.scale.z")
        
        // 何故か動いていない
//        if flash {
//            let waitAction = SCNAction.wait(duration: FocusSquare.animationDuration * 0.75)
//            let fadeInAction = SCNAction.fadeOpacity(by: 0.25, duration: FocusSquare.animationDuration * 0.125)
//            let fadeOutAction = SCNAction.fadeOpacity(by: 0.0, duration: FocusSquare.animationDuration * 0.125)
//            fillPlane.runAction(SCNAction.sequence([waitAction, fadeInAction, waitAction, fadeOutAction]))
//
//            let flashSquareAction = flashAnimation(duration: FocusSquare.animationDuration * 0.25)
//            for segment in segments {
//                segment.runAction(.sequence([waitAction, flashSquareAction]))
//            }
//        }
    }
    
    private func scaleAnimation(for keyPath: String) -> CAKeyframeAnimation {
        let scaleAnimation = CAKeyframeAnimation(keyPath: keyPath)
        let easeOut = CAMediaTimingFunction(name: .easeOut)
        let easeInOut = CAMediaTimingFunction(name: .easeInEaseOut)
        let linear = CAMediaTimingFunction(name: .linear)
        
        let size = FocusSquare.size
        let ts = FocusSquare.size * FocusSquare.scaleForClosedSquare
        let values = [size, size * 1.15, size * 1.15, ts * 0.97, ts]
        let keyTimes: [NSNumber] = [0.00, 0.25, 0.50, 0.75, 1.00]
        let timingFunctions = [easeOut, linear, easeOut, easeInOut]
        
        scaleAnimation.values = values
        scaleAnimation.keyTimes = keyTimes
        scaleAnimation.timingFunctions = timingFunctions
        scaleAnimation.duration = FocusSquare.animationDuration
        return scaleAnimation
    }
    
    private func displayAsClose(for hitTestResult: ARHitTestResult, planeAnchor: ARPlaneAnchor, camera: ARCamera?) {
        performCloseAnimation(flash: !anchorsOfVisitedPlanes.contains(planeAnchor))
        anchorsOfVisitedPlanes.insert(planeAnchor)
        let position = hitTestResult.worldTransform.translation
        recentFocusSquarePositions.append(position)
        updateTransform(for: position, hitTestResult: hitTestResult, camera: camera)
    }
    
    private func displayAsOpen(for hitTestResult: ARHitTestResult, camera: ARCamera?) {
        performOpenAnimation()
        let position = hitTestResult.worldTransform.translation
        recentFocusSquarePositions.append(position)
        updateTransform(for: position, hitTestResult: hitTestResult, camera: camera)
    }
    
    private func updateTransform(for position: float3, hitTestResult: ARHitTestResult, camera: ARCamera?) {
        recentFocusSquarePositions = Array(recentFocusSquarePositions.suffix(10))
        
        let average = recentFocusSquarePositions.reduce(float3(0), {$0 + $1}) / Float(recentFocusSquarePositions.count)
        simdPosition = average
        simdScale = float3(scaleBasedOnDistance(camera: camera))
        
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
            recentFocusSquareAlignment.append(alignment!)
        }
        
        recentFocusSquareAlignment = Array(recentFocusSquareAlignment.suffix(20))
        let horizontalHistory = recentFocusSquareAlignment.filter({ $0 == .horizontal}).count
        let verticalHistory = recentFocusSquareAlignment.filter({ $0 == .vertical}).count
    
        if alignment == .horizontal && horizontalHistory > 15 ||
            alignment == .vertical && verticalHistory > 10 ||
            hitTestResult.anchor is ARPlaneAnchor {
            if alignment != currentAlignment {
                shouldAnimateAlignmentChange = true
                currentAlignment = alignment
                recentFocusSquareAlignment.removeAll()
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

private func pulseAction() -> SCNAction {
    let pulseOutAction = SCNAction.fadeOpacity(by: 0.4, duration: 0.5)
    let pulseInAction = SCNAction.fadeOpacity(by: 1.0, duration: 0.5)
    
    pulseOutAction.timingMode = .easeInEaseOut
    pulseInAction.timingMode = .easeInEaseOut
    
    return SCNAction.repeatForever(SCNAction.sequence([pulseOutAction, pulseInAction]))
}

private func flashAnimation(duration: TimeInterval) -> SCNAction {
    let action = SCNAction.customAction(duration: duration) { (node, elapsedTime) in
        let elapsedTimePercentage = elapsedTime / CGFloat(duration)
        let saturation = 2.8 * (elapsedTimePercentage - 0.5) * (elapsedTimePercentage - 0.5) + 0.3
        if let material = node.geometry?.firstMaterial {
            material.diffuse.contents = UIColor(hue: 0.1333, saturation: saturation, brightness: 1.0, alpha: 1.0)
        }
    }
    return action
}
