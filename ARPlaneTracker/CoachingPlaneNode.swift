//
//  PlaneNode.swift
//  ARPlaneTracker
//
//  Created by kahayash on 7/24/1 R.
//  Copyright © 1 Reiwa Kazuhiro Hayashi. All rights reserved.
//

import Foundation
import ARKit

public class CoachingPlaneNode: SCNNode {
    public let anchor: ARPlaneAnchor
    public let planeGeometry: SCNBox
    
    public init(anchor: ARPlaneAnchor, isHidden: Bool) {
        self.anchor = anchor
        
        self.planeGeometry = SCNBox(
            width: CGFloat(anchor.extent.x),
            height: 0,
            length: CGFloat(anchor.extent.z),
            chamferRadius: 0)
        
        super.init()
        
        let material = SCNMaterial()
        let img = UIImage(named: "Grid", in: Bundle(for: type(of: self)), compatibleWith: nil)
        material.diffuse.contents = img
        
        let transparentMaterial = SCNMaterial()
        transparentMaterial.diffuse.contents = UIColor(white: 1, alpha: 0)
        
        if isHidden {
            planeGeometry.materials = [transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial]
        } else {
            planeGeometry.materials = [transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, material, transparentMaterial]
        }
        
        let planeNode = SCNNode(geometry: planeGeometry)
        planeNode.position = SCNVector3(0, 0, 0)
        
        planeNode.physicsBody = SCNPhysicsBody(
            type: .kinematic,
            shape: SCNPhysicsShape(geometry: planeGeometry, options: nil))
        
        setTextureScale()
        
        addChildNode(planeNode)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func update(anchor: ARPlaneAnchor) {
        planeGeometry.width = CGFloat(anchor.extent.x)
        planeGeometry.length = CGFloat(anchor.extent.z)
        
        position = SCNVector3(anchor.center.x, 0, anchor.center.z)
        
        guard let node = childNodes.first else { return }
        
        node.physicsBody = SCNPhysicsBody(
            type: .kinematic,
            shape: SCNPhysicsShape(geometry: planeGeometry, options: nil))
        
        setTextureScale()
        
    }
    
    public func setTextureScale() {
        let width = planeGeometry.width
        let height = planeGeometry.length
        
        
        let material = planeGeometry.materials[4]
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(width), Float(height), 1)
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
    }
    
    public func hide() {
        let transparentMaterial = SCNMaterial()
        transparentMaterial.diffuse.contents = UIColor(white: 1, alpha: 0)
        planeGeometry.materials = [transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial]
    }
    
    public func show() {
        let transparentMaterial = SCNMaterial()
        transparentMaterial.diffuse.contents = UIColor(white: 1, alpha: 0)
        planeGeometry.materials = [transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial]
    }
}

