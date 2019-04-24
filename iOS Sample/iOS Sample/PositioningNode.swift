//
//  PositioningNode.swift
//  ARPlaneTracker
//
//  Created by Kazuhiro Hayashi on 2019/04/24.
//  Copyright © 2019 Kazuhiro Hayashi. All rights reserved.
//

import SceneKit

public class PositioningNode: SCNNode {
    let size: Float = 0.17
    let scaleForClosedSquare: Float = 0.97
    let sideLengthForOpenSegments: Float = 0.2
    let animationDuration = 0.7
    
    private var segments: [PositioningNode.Segment] = []
    private let fillPlane = FillPlane()
    
    private var isOpen = false
    private var isAnimating = false
    
    public override init() {
        super.init()
        
        
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
        let c: Float = fillPlane.thickness / 2
        s1.simdPosition += float3(-(sl / 2 - c), -(sl - c), 0)
        s2.simdPosition += float3((sl / 2 - c), -(sl - c), 0)
        s3.simdPosition += float3(-sl, -sl / 2, 0)
        s4.simdPosition += float3(sl, -sl / 2, 0)
        s5.simdPosition += float3(-sl, sl / 2, 0)
        s6.simdPosition += float3(sl, sl / 2, 0)
        s7.simdPosition += float3(-(sl / 2 - c), sl - c, 0)
        s8.simdPosition += float3(sl / 2 - c, sl - c, 0)
        
        eulerAngles.x = .pi / 2
        simdScale = float3(repeating: size * scaleForClosedSquare)
        for segment in segments {
            addChildNode(segment)
        }
        
        addChildNode(fillPlane)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func open() {
        for segment in segments {
            segment.open()
        }
    }
    
    
    func close() {
        for segment in segments {
            segment.close()
        }
    }
    
    public func performOpenAnimation() {
        guard !isOpen, !isAnimating else { return }
        isOpen = true
        isAnimating = true
        
        SCNTransaction.begin()
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        SCNTransaction.animationDuration = animationDuration / 4
        opacity = 1.0
        open()
        SCNTransaction.completionBlock = {
            self.runAction(pulseAction(), forKey: "pulse")
            self.isAnimating = false
        }
        SCNTransaction.commit()
        
        SCNTransaction.begin()
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        SCNTransaction.animationDuration = animationDuration / 4
        simdScale = float3(repeating: size)
        SCNTransaction.commit()
    }
    
    public func performCloseAnimation(flash: Bool = false) {
        guard isOpen, !isAnimating else { return }
        isOpen = false
        isAnimating = true
        
        removeAction(forKey: "pulse")
        opacity = 1.0
        
        SCNTransaction.begin()
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        SCNTransaction.animationDuration = animationDuration / 2
        opacity = 0.99
        SCNTransaction.completionBlock = {
            SCNTransaction.begin()
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
            SCNTransaction.animationDuration = self.animationDuration / 4
            self.close()
            SCNTransaction.completionBlock = { self.isAnimating = false }
            SCNTransaction.commit()
        }
        SCNTransaction.commit()
        
        addAnimation(scaleAnimation(for: "transform.scale.x"), forKey: "transfirm.scale.x")
        addAnimation(scaleAnimation(for: "transform.scale.y"), forKey: "transfirm.scale.y")
        addAnimation(scaleAnimation(for: "transform.scale.z"), forKey: "transfirm.scale.z")
        
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
        
        let ts = size * scaleForClosedSquare
        let values = [size, size * 1.15, size * 1.15, ts * 0.97, ts]
        let keyTimes: [NSNumber] = [0.00, 0.25, 0.50, 0.75, 1.00]
        let timingFunctions = [easeOut, linear, easeOut, easeInOut]
        
        scaleAnimation.values = values
        scaleAnimation.keyTimes = keyTimes
        scaleAnimation.timingFunctions = timingFunctions
        scaleAnimation.duration = animationDuration
        return scaleAnimation
    }
    
}

extension PositioningNode {
    public class FillPlane: SCNNode {
        let thickness: Float = 0.018
        let fillColor = #colorLiteral(red: 1, green: 0.9254901961, blue: 0.4117647059, alpha: 1)
        
        public override init() {
            super.init()
            
            let correctionFactor = thickness / 2
            let length = CGFloat(1.0 - thickness * 2 + correctionFactor)
            
            let plane = SCNPlane(width: length, height: length)
            geometry = plane
            name = "FillPlane"
            opacity = 0
            
            let material = plane.firstMaterial!
            material.diffuse.contents = fillColor
            material.isDoubleSided = true
            material.ambient.contents = UIColor.black
            material.lightingModel = .constant
            material.emission.contents = fillColor
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension PositioningNode {
    
    enum Corner {
        case topLeft
        case topRight
        case bottomRight
        case bottomLeft
    }
    
    enum Alignment {
        case horizontal
        case vertical
    }
    
    enum Direction {
        case up, down, left, right
        
        var reversed: Direction {
            switch self {
            case .up: return .down
            case .down: return .up
            case .left: return .right
            case .right: return .left
            }
        }
    }
    
    class Segment: SCNNode {
        let primaryColor = #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1)
        
        static let thickness: CGFloat = 0.018
        static let length: CGFloat = 0.5
        static let openLength: CGFloat = 0.2
        
        let corner: Corner
        let alignment: Alignment
        let plane: SCNPlane
        
        init(name: String, corner: Corner, alignment: Alignment) {
            self.corner = corner
            self.alignment = alignment
            
            switch alignment {
            case .vertical:
                plane = SCNPlane(width: Segment.thickness, height: Segment.length)
            case .horizontal:
                plane = SCNPlane(width: Segment.length, height: Segment.thickness)
            }
            super.init()
            self.name = name
            
            let material = plane.firstMaterial!
            material.diffuse.contents = primaryColor
            material.isDoubleSided = true
            material.ambient.contents = UIColor.black
            material.lightingModel = .constant
            material.emission.contents = primaryColor
            geometry = plane
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        var openDirection: Direction {
            switch (corner, alignment) {
            case (.topLeft,      .horizontal):  return .left
            case (.topLeft,      .vertical):    return .up
            case (.topRight,     .horizontal):  return .right
            case (.topRight,     .vertical):    return .up
            case (.bottomLeft,   .horizontal):  return .left
            case (.bottomLeft,   .vertical):    return .down
            case (.bottomRight,  .horizontal):  return .right
            case (.bottomRight,  .vertical):    return .down
            }
        }
        
        func open() {
            if alignment == .horizontal {
                plane.width = Segment.openLength
            } else {
                plane.height = Segment.openLength
            }
            
            let offset = Segment.length / 2 - Segment.openLength / 2
            updatePosition(with: Float(offset), for: openDirection)
        }
        
        func close() {
            let oldLength: CGFloat
            if alignment == .horizontal {
                oldLength = plane.width
                plane.width = Segment.length
            } else {
                oldLength = plane.height
                plane.height = Segment.length
            }
            
            let offset = Segment.length / 2 - oldLength / 2
            updatePosition(with: Float(offset), for: openDirection.reversed)
        }
        
        
        private func updatePosition(with offset: Float, for direction: Direction) {
            switch direction {
            case .left:     position.x -= offset
            case .right:    position.x += offset
            case .up:       position.y -= offset
            case .down:     position.y += offset
            }
        }
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
