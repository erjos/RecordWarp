//
//  AnimateTestViewController.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 11/12/19.
//  Copyright © 2019 Ethan Joseph. All rights reserved.
//

import UIKit

class AnimateTestViewController: UIViewController {

    @IBOutlet weak var container: UIView!
    
    @IBOutlet weak var purple: UIView!
    @IBOutlet weak var pink: UIView!
    @IBOutlet weak var orange: UIView!
    @IBOutlet weak var teel: UIView!
    
    var orderedViews = [UIView]()
    var shouldAnimate = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        orderedViews = [purple, pink, orange, teel]
        //remove all constraints
        for view in orderedViews {
            removeAllConstraints(view)
        }
    }
    
    //get the next position of the block as it's frame and then pass it that frame to inside the block
    private func startAnimation() {
        
        //animate with next frame
            UIView.animateKeyframes(withDuration: 1.0, delay: 0.0, options: [], animations: {
                //bring first to the front
                self.view.bringSubview(toFront: self.orderedViews[0])
                //move first to last
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                    let last = self.orderedViews[3].frame
                    let first = self.orderedViews[0].frame
                    let second = self.orderedViews[1].frame
                    let third = self.orderedViews[2].frame
                    self.orderedViews[0].frame = last
                    self.orderedViews[1].frame = first
                    self.orderedViews[2].frame = second
                    self.orderedViews[3].frame = third
                    self.view.layoutIfNeeded()
                    self.updateOrder()
                }
            }, completion: { (bool) in
                self.startAnimation()
        })
    }
    
    private func updateOrder() {
        let first = orderedViews.remove(at: 0)
        orderedViews.append(first)
    }
    
    private func removeAllConstraints(_ view: UIView) {
        for constraints in view.constraints {
            if constraints.constant != 150 {
                constraints.isActive = false
            }
        }
    }

    @IBAction func didTapPurple(_ sender: Any) {
        shouldAnimate = !shouldAnimate
        self.startAnimation()
    }
}
