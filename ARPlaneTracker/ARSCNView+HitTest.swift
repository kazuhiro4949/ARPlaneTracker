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
import ARKit
//
//extension ARSCNView {
//    func smartHitTest(_ point: CGPoint,
//                      infinitePlane: Bool = false,
//                      objectPosition: float3? = nil) -> ARHitTestResult? {
//        let results = hitTest(point, types: [.existingPlaneUsingGeometry, .existingPlaneUsingExtent, .estimatedHorizontalPlane, .existingPlane])
//        if let result = results.first(where: { $0.type == .existingPlaneUsingGeometry }), result.anchor is ARPlaneAnchor {
//            return result
//        }
//        
//        if infinitePlane {
//            let infinitePlaneResults = hitTest(point, types: .existingPlane)
//            for infinitePlaneResult in infinitePlaneResults {
//                if let planeAnchor = infinitePlaneResult.anchor as? ARPlaneAnchor {
//                    if planeAnchor.alignment == .vertical {
//                        return infinitePlaneResult
//                    } else {
//                        if let objectY = objectPosition?.y {
//                            let planeY = infinitePlaneResult.worldTransform.translation.y
//                            if objectY > planeY - 0.05 && objectY < planeY + 0.05 {
//                                return infinitePlaneResult
//                            }
//                        } else {
//                            return infinitePlaneResult
//                        }
//                    }
//                }
//            }
//        }
//        
//        return results.first(where: { $0.type == .estimatedHorizontalPlane })
//    }
//    
//    func centerHitTest( objectPosition: float3? = nil) -> ARHitTestResult? {
//        return smartHitTest(
//            CGPoint(x: bounds.midX, y: bounds.midY),
//            infinitePlane: infinitePlane,
//            objectPosition: objectPosition)
//    }
//    
//    func 
//}
