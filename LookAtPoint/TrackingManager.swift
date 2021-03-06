//
//  TrackingManager.swift
//  LookAtPoint
//
//  Created by 副島拓哉 on 2021/07/14.
//

import Foundation
import ARKit
import SceneKit

protocol TrackingManagerDelegate: AnyObject {
    func didUpdate(lookingPoint: CGPoint)
}

class TrackingManager:NSObject {
    
    private weak var delegate: TrackingManagerDelegate?

    private var sceneView: ARSCNView!

    private let configuration = ARFaceTrackingConfiguration()
    
    //private let configuration = ARWorldTrackingConfiguration()
    
    private var isPhone : Bool?

    // 顔のNode
    private var faceNode = SCNNode()

    // 目のNode
    private var leftEyeNode = SCNNode()
    private var rightEyeNode = SCNNode()

    // 目の視線の先のNode
    private var leftEyeTargetNode = SCNNode()
    private var rightEyeTargetNode = SCNNode()
    
    // 目線の値を格納する配列
    private var lookingPositionXs: [CGFloat] = []
    private var lookingPositionYs: [CGFloat] = []

    // 実際のiPhone12Proの物理的なスクリーンサイズ(m)
    private let phoneScreenMeterSize = CGSize(width: 0.0649923, height: 0.14065)

    // 実際のiPhone12Proのポイント値でのスクリーンサイズ
    private let phoneScreenPointSize = CGSize(width: 390, height: 844)
    
    //実際のiPadPro12.9の物理的なスクリーンサイズ(m)
    private let tabletScreenMeterSize = CGSize(width: 0.196535, height: 0.262174)
    // 実際のiPadPro12.9のポイント値でのスクリーンサイズ
    private let tabletScreenPointSize = CGSize(width: 2048, height: 2732)
    
//    private let tabletScreenMeterSize = CGSize(width: 0.262174, height: 0.196535 )
//
//    // 実際のiPadPro12.9のポイント値でのスクリーンサイズ
//    private let tabletScreenPointSize = CGSize(width: 2732, height: 2048)

    // 仮想空間のiPhoneのNode
    private var virtualPhoneNode: SCNNode = SCNNode()

    // 仮想空間のiPhoneのScreenNode
    private var virtualScreenNode: SCNNode = {
        let screenGeometry = SCNPlane(width: 1, height: 1)
        return SCNNode(geometry: screenGeometry)
    }()

    init(with sceneView: ARSCNView, delegate: TrackingManagerDelegate) {
        super.init()
        print("DEBAC[init]")
        
        if UIScreen.main.bounds.size.width == 390 {
            isPhone = true
        } else {
            isPhone = false
        }

        self.sceneView = sceneView
        self.delegate = delegate
        sceneView.delegate = self
        sceneView.session.delegate = self

        // SetupNode
        sceneView.scene.rootNode.addChildNode(faceNode) // 顔のNodeをsceneViewに追加
        sceneView.scene.rootNode.addChildNode(virtualPhoneNode) //仮想空間のiPhoneのNodeをsceneViewに追加
        virtualPhoneNode.addChildNode(virtualScreenNode) // 仮想空間のiPhoneにscreenNodeを追加
        faceNode.addChildNode(leftEyeNode) // 顔のnodeに左目のNodeを追加
        faceNode.addChildNode(rightEyeNode) // // 顔のnodeに右目のNodeを追加
        leftEyeNode.addChildNode(leftEyeTargetNode) //左目のNodeに視線TargetNodeを追加
        rightEyeNode.addChildNode(rightEyeTargetNode) //右目のNodeに視線TargetNodeを追加

        // TargetNodeを目の中心から2メートル離れたところに設定
        leftEyeTargetNode.position.z = 2
        rightEyeTargetNode.position.z = 2
    }

    func runSession() {
        // sessionを開始
//        if ARWorldTrackingConfiguration.isSupported {
//                    configuration.isWorldTrackingEnabled = true
//            } else {
//
//            }
        print("DEBAC[runSession()]")
            if ARFaceTrackingConfiguration.isSupported {
                //configuration.userFaceTrackingEnabled = true
            } else {
        
            }
        sceneView.session.run(configuration,options: [.resetTracking, .removeExistingAnchors])
        print("qaaa",configuration)
    }

    func pauseSession() {
        // sessionを停止
        sceneView.session.pause()
    }
}
extension TrackingManager: ARSCNViewDelegate {

    // 新しい顔のNodeが追加されたら
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("DEBAC[renderer]")
        // faceAnchorを取得
        faceNode.transform = node.transform
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }

        update(withFaceAnchor: faceAnchor)
    }
    
    func update(withFaceAnchor anchor: ARFaceAnchor) {
        print("DEBAC[update]")
        // 各eyeNodeのsimdTransfromにARFaceAnchorのeyeTransfromを代入
        rightEyeNode.simdTransform = anchor.rightEyeTransform
        leftEyeNode.simdTransform = anchor.leftEyeTransform

        var leftEyeLookingPoint = CGPoint()
        var rightEyeLookingPoint = CGPoint()

        DispatchQueue.main.async {

            // 仮想空間に配置したiPhoneNodeのHitTest
            // 目の中心と2m先に追加したTargetNodeの間で、virtualPhoneNodeとの交点を調べる
            let phoneScreenEyeRightHitTestResults = self.virtualPhoneNode.hitTestWithSegment(from: self.rightEyeTargetNode.worldPosition, to:
                                                                                                self.rightEyeNode.worldPosition, options: nil)
            print("olm",self.virtualPhoneNode.hitTestWithSegment(from: self.rightEyeTargetNode.worldPosition, to:
                                                                    self.rightEyeNode.worldPosition, options: nil))
            print("phoneScreenEyeRightHitTestResults", phoneScreenEyeRightHitTestResults,self.virtualPhoneNode,self.rightEyeTargetNode,self.rightEyeNode)

            let phoneScreenEyeLeftHitTestResults = self.virtualPhoneNode.hitTestWithSegment(from: self.leftEyeTargetNode.worldPosition, to:
            self.leftEyeNode.worldPosition, options: nil)

            //HitTestがEmptyだった場合はパスする
            if phoneScreenEyeRightHitTestResults.isEmpty == false || phoneScreenEyeLeftHitTestResults.isEmpty == false {
                // HitTestの結果から各xとyを取得
                for result in phoneScreenEyeRightHitTestResults {
                    if self.isPhone == true {
                        rightEyeLookingPoint.x = CGFloat(result.localCoordinates.x) / self.phoneScreenMeterSize.width * self.phoneScreenPointSize.width
                        rightEyeLookingPoint.y = CGFloat(result.localCoordinates.y) / self.phoneScreenMeterSize.height * self.phoneScreenPointSize.height
                    } else {
                        rightEyeLookingPoint.x = CGFloat(result.localCoordinates.x) / self.tabletScreenMeterSize.width * self.tabletScreenPointSize.width
                        rightEyeLookingPoint.y = CGFloat(result.localCoordinates.y) / self.tabletScreenMeterSize.height * self.tabletScreenPointSize.height
                    }
                }

                for result in phoneScreenEyeLeftHitTestResults {
                    if self.isPhone == true {
                        leftEyeLookingPoint.x = CGFloat(result.localCoordinates.x) / self.phoneScreenMeterSize.width * self.phoneScreenPointSize.width
                        leftEyeLookingPoint.y = CGFloat(result.localCoordinates.y) / self.phoneScreenMeterSize.height * self.phoneScreenPointSize.height
                    } else {
                        leftEyeLookingPoint.x = CGFloat(result.localCoordinates.x) / self.tabletScreenMeterSize.width * self.tabletScreenPointSize.width
                        leftEyeLookingPoint.y = CGFloat(result.localCoordinates.y) / self.tabletScreenMeterSize.height * self.tabletScreenPointSize.height
                    }
                }

                // 最新の位置を追加し、直近の10通りの位置を配列で保持する
                let suffixNumber: Int = 10
                self.lookingPositionXs.append((rightEyeLookingPoint.x + leftEyeLookingPoint.x) / 2)
                self.lookingPositionYs.append(-(rightEyeLookingPoint.y + leftEyeLookingPoint.y) / 2)
                self.lookingPositionXs = Array(self.lookingPositionXs.suffix(suffixNumber))
                self.lookingPositionYs = Array(self.lookingPositionYs.suffix(suffixNumber))
                print("aveXs",self.lookingPositionXs,self.lookingPositionYs)

                // 取得した配列の平均を出す
                let avarageLookAtPositionX = self.lookingPositionXs.average
                let avarageLookAtPositionY = self.lookingPositionYs.average
                print("ave",avarageLookAtPositionX,avarageLookAtPositionY)

                let lookingPoint = CGPoint(x: avarageLookAtPositionX, y: avarageLookAtPositionY)
                self.delegate?.didUpdate(lookingPoint: lookingPoint)
            }
        }
    }
}

extension TrackingManager: ARSessionDelegate {

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {

        // 現在のカメラのTransfromを取得し、virtualPhoneNodeに代入
        guard let pointOfViewTransfrom = sceneView.pointOfView?.transform
        else { return }
        virtualPhoneNode.transform = pointOfViewTransfrom
    }

    // アンカーが更新されたら
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        faceNode.transform = node.transform
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        update(withFaceAnchor: faceAnchor)
    }
}

extension Collection where Element == CGFloat {

    var average: CGFloat {
        let totalNumber = sum()
        return totalNumber / CGFloat(count)
    }

    private func sum() -> CGFloat {
            return reduce(CGFloat(0), +)
        }
}
