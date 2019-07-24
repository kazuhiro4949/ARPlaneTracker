//
//  CoachingPlane.swift
//  ARPlaneTracker
//
//  Created by kahayash on 7/24/1 R.
//  Copyright © 1 Reiwa Kazuhiro Hayashi. All rights reserved.
//

import Foundation
import ARKit

public class CoachingPlane {
    private(set) var grid = [UUID: CoachingPlaneNode]()

    public init() {}
    
    public func add(on node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let grid = CoachingPlaneNode(anchor: planeAnchor, isHidden: false)
        grid.renderingOrder = -1
        self.grid[planeAnchor.identifier] = grid
        
        
        DispatchQueue.main.async {
            node.addChildNode(grid)
        }
    }
    
    public func update(for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let plane = grid[planeAnchor.identifier]
        
        plane?.update(anchor: planeAnchor)
    }
    
    public func remove(for anchor: ARAnchor) {
        grid[anchor.identifier] = nil
    }
}
