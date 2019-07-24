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

