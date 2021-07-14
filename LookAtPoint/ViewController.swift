//
//  ViewController.swift
//  LookAtPoint
//
//  Created by 副島拓哉 on 2021/07/14.
//

import UIKit
import ARKit
import SceneKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    
    private var trackingManager: TrackingManager!
    
    private var lookAtPoint: CGPoint?
    
    private var lookPointLabel:UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        trackingManager = TrackingManager(with: sceneView, delegate: self)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        trackingManager.runSession()
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        trackingManager.pauseSession()
        UIApplication.shared.isIdleTimerDisabled = false
    }
    @IBAction func lookAtPointLabelButton(_ sender: Any) {
        guard let lookAtPoint = lookAtPoint else { return }
        labelSetting(lookingPoint: lookAtPoint)
    }
    
}

extension ViewController: TrackingManagerDelegate {
    func didUpdate(lookingPoint: CGPoint) {
        print("dev",lookingPoint)
        lookAtPoint = lookingPoint
    }
}

extension ViewController {
    func labelSetting(lookingPoint: CGPoint) {
        lookPointLabel = UILabel()
        lookPointLabel.text = "Look!"
        lookPointLabel.backgroundColor = UIColor.black
        lookPointLabel.frame = CGRect(x: lookingPoint.x, y:lookingPoint.y, width:50, height:50)
        self.view.addSubview(lookPointLabel)
    }
}

