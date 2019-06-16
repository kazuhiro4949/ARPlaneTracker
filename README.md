# ARPlaneTracker
Under Construction...

# What's this?

# Feature
- [x] easy to coach detected area
- [x] easy to associate with your ARSCNView
- [x] custumizable coaching object

# Requirements
+ iOS 12.0+
+ Xcode 10.0+
+ Swift 5.0

# Installation

### CocoaPods
+ Install CocoaPods
```
> gem install cocoapods
> pod setup
```
+ Create Podfile
```
> pod init
```
+ Edit Podfile
```ruby
target 'YourProject' do
  use_frameworks!

  pod "ARPlaneTracker" # add

  target 'YourProject' do
    inherit! :search_paths
  end

  target 'YourProject' do
    inherit! :search_paths
  end

end
```

+ Install

```
> pod install
```
open .xcworkspace

## Carthage
+ Install Carthage from Homebrew
```
> ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
> brew update
> brew install carthage
```
+ Move your project dir and create Cartfile
```
> touch Cartfile
```
+ add the following line to Cartfile
```
github "kazuhiro4949/ARPlaneTracker"
```
+ Create framework
```
> carthage update --platform iOS
```

+ In Xcode, move to "Genera > Build Phase > Linked Frameworks and Library"
+ Add the framework to your project
+ Add a new run script and put the following code
```
/usr/local/bin/carthage copy-frameworks
```
+ Click "+" at Input file and Add the framework path
```
$(SRCROOT)/Carthage/Build/iOS/ARPlaneTracker.framework
```
+ Write Import statement on your source file
```
import ARPlaneTracker
```

# Usage

## 1. Instanciate ARPlaneTracker
```swift
class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!    
    let arPlaneTracker = ARPlaneTracker()
    //...
}
```

## 2. Add ARPlaneTracker object to the root scene node
```swift
override func viewDidLoad() {
        // ...
        arPlaneTracker.sceneView = sceneView
        arPlaneTracker.delegate = self
        sceneView.scene.rootNode.addChildNode(arPlaneTracker)
}
```

## 3. Add a coaching node to ARPlaneTracker object
```swift
let coachingNode = SCNNode()

override func viewDidLoad() {
        // ...
        arPlaneTracker.addChildNode(coachingNode)
}
```

## 4. Update the state of ARPlaneTrack object in ARSCNViewDelegate
```swift
extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.arPlaneTracker.updateTracker()
        }
    }
}
```

## 5. Animate coaching node in ARPlaneTrackerDelegate

```swift
extension ViewController: ARPlaneTrackerDelegate {
    func planeTracker(_ planeTracker: ARPlaneTracker, didDetect horizontalPlaneAnchor: ARPlaneAnchor, hitTestResult: ARHitTestResult, camera: ARCamera?) {
        // add activate animation to coachingNode
    }
    
    func planeTracker(_ planeTracker: ARPlaneTracker, failToDetectHorizontalAnchorWith hitTestResult: ARHitTestResult, camera: ARCamera?) {
        // add deactivate animation to coachingNode
    }
}
