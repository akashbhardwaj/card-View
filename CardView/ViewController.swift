//
//  ViewController.swift
//  CardView
//
//  Created by Akash Bhardwaj on 29/10/18.
//  Copyright © 2018 Akash Bhardwaj. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    enum CardState {
        case expanded, collapsed
    }
    
    var cardView: CardViewController!
    
    var visualEffectView: UIVisualEffectView!
    
    var cardHeight = 560
    var cardHandleHeight = 100
    
    var runningAnimations = [UIViewPropertyAnimator]()
    
    var cardVisible = false
    
    var newState: CardState {
        return cardVisible ? .collapsed : .expanded
    }
    
    var animationFractionWhenInterupted: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCardView()
    }
    
    func setupCardView () {
        visualEffectView = UIVisualEffectView()
        visualEffectView.frame = self.view.frame
        self.view.addSubview(visualEffectView)
        
        
        cardView = CardViewController(nibName: "CardViewController", bundle: nil)
        self.addChild(cardView)
        self.view.addSubview(cardView.view)
        let height = self.view.frame.height - CGFloat(cardHandleHeight)
        cardView.view.frame = CGRect(x: 0.0, y: height, width: self.view.frame.width, height: CGFloat(cardHeight))
        cardView.view.clipsToBounds = true
        
        let tapGestureRecogonizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleCardTap(recogonizer:)))
        let panGestureRecogonizer = UIPanGestureRecognizer(target: self, action: #selector(ViewController.handleCardPan(recogonizer:)))
        cardView.handleView.addGestureRecognizer(tapGestureRecogonizer)
        cardView.handleView.addGestureRecognizer(panGestureRecogonizer)
        
    }

    @objc
    func handleCardTap(recogonizer: UITapGestureRecognizer) {
        switch recogonizer.state {
        case .ended:
            animationIfNeeded(state: newState, timeInterval: 0.6)
        default:
            break
        }
    }
    @objc
    func handleCardPan(recogonizer: UIPanGestureRecognizer) {
        switch recogonizer.state {
        case .began:
            startCardInteractiveTransition(cardState: newState, timeInterval: 0.6)
        case .changed:
            let userInterActiveThread = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)
            userInterActiveThread.async {
                let translation = recogonizer.translation(in: self.cardView.handleView)
                var fractionComplete = translation.y / CGFloat(self.cardHeight)
                fractionComplete = self.cardVisible ? fractionComplete : -fractionComplete
                DispatchQueue.main.async {
                    self.updateInteractiveTransition(fractionCompleted: fractionComplete)
                }
            }
//            let translation = recogonizer.translation(in: self.cardView.handleView)
//            var fractionComplete = translation.y / CGFloat(cardHeight)
//            fractionComplete = cardVisible ? fractionComplete : -fractionComplete
//            updateInteractiveTransition(fractionCompleted: fractionComplete)
        case .ended:
            continueInteractiveTransition()
        default:
            break
        }
    }
    
    func animationIfNeeded (state: CardState, timeInterval: TimeInterval) {
        if runningAnimations.isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: timeInterval, dampingRatio: 0.7) {
                switch state {
                case .collapsed:
                    self.cardView.view.frame.origin.y = self.view.frame.height - CGFloat(self.cardHandleHeight)
                case .expanded:
                    self.cardView.view.frame.origin.y = self.view.frame.height - CGFloat(self.cardHeight)
                }
            }
            frameAnimator.addCompletion { (_) in
                self.cardVisible = !self.cardVisible
                self.runningAnimations.removeAll()
            }
            frameAnimator.startAnimation()
            runningAnimations.append(frameAnimator)
            
            let cornerRadiusAnimator = UIViewPropertyAnimator(duration: timeInterval, curve: .linear) {
                switch state {
                case .expanded:
                    self.cardView.view.layer.cornerRadius = 12
                case .collapsed:
                    self.cardView.view.layer.cornerRadius = 0
                }
            }
            cornerRadiusAnimator.startAnimation()
            runningAnimations.append(cornerRadiusAnimator)
            
            let blurAnimator = UIViewPropertyAnimator(duration: timeInterval, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.visualEffectView.effect = UIBlurEffect(style: .dark)
                case .collapsed:
                    self.visualEffectView.effect = nil
                }
            }
            blurAnimator.startAnimation()
            runningAnimations.append(blurAnimator)
        }
    }
    
    func startCardInteractiveTransition (cardState: CardState, timeInterval: TimeInterval) {
        if runningAnimations.isEmpty {
            animationIfNeeded(state: cardState, timeInterval: timeInterval)
        }
        for animator in runningAnimations {
            animator.pauseAnimation()
            animationFractionWhenInterupted = animator.fractionComplete
        }
    }
    
    func updateInteractiveTransition (fractionCompleted: CGFloat) {
        for animator in runningAnimations {
            animator.fractionComplete = fractionCompleted + animationFractionWhenInterupted
        }
    }
    
    func continueInteractiveTransition () {
        for animator in runningAnimations {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0.0)
        }
    }
}
