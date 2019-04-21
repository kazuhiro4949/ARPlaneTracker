//
//  FocusSquareSegment.swift
//  AR3DMeasure
//
//  Created by Kazuhiro Hayashi on 2019/03/30.
//  Copyright © 2019 Kazuhiro Hayashi. All rights reserved.
//

import UIKit
import SceneKit

extension FocusSquare {
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
            material.diffuse.contents = FocusSquare.primaryColor
            material.isDoubleSided = true
            material.ambient.contents = UIColor.black
            material.lightingModel = .constant
            material.emission.contents = FocusSquare.primaryColor
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
