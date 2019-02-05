//
//  ViewController.swift
//  OnboardingCarouselAnimation
//
//  Created by Casey Evanish on 1/29/19.
//  Copyright © 2019 Casey Evanish. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var frontImage: UIImageView!
    var backImage: UIImageView!
    
    private var strings: [(String, String)] = [
        ("Heading #1", "This is Subheader #1"),
        ("Heading #2", "This is Subheader #2"),
        ("Heading #3", "This is Subheader #3")
    ]
    
    private var images: [UIImage?] = [
        UIImage(named: "Image-1"),
        UIImage(named: "Image-2"),
        UIImage(named: "Image-3")
    ]
    
    private enum Direction {
        case left, right
    }
    
    private var currentIndex: Int = 0
    // the offset of every label from the edge of the screen
    private var _LABEL_X_OFFSET: CGFloat = 16.0
    private var pages: [(UILabel, UILabel)] = []
    
    private let _TOP_FONT = UIFont.systemFont(ofSize: 32, weight: .semibold)
    private let _BOTTOM_FONT = UIFont.systemFont(ofSize: 24, weight: .regular)
    
    // set up all the views
    override func loadView() {
        super.loadView()
        let frontImage = UIImageView(image: UIImage(named: "Image-1"))
        frontImage.translatesAutoresizingMaskIntoConstraints = true
        frontImage.frame.size = CGSize(width: 130, height: 130)
        frontImage.center = self.view.center.applying(CGAffineTransform(translationX: 0, y: -100))
        frontImage.layer.opacity = 1.0
        self.view.addSubview(frontImage)
        self.frontImage = frontImage
        
        let backImage = UIImageView(image: UIImage(named: "Image-2"))
        backImage.translatesAutoresizingMaskIntoConstraints = true
        backImage.frame = frontImage.frame
        backImage.layer.transform = CATransform3DRotate(CATransform3DIdentity, .pi, 0, 1, 0)
        backImage.layer.opacity = 0.0
        self.view.addSubview(backImage)
        self.backImage = backImage
        
        (0...2).forEach({ offset in
            let topLabel = UILabel(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.frame.width - _LABEL_X_OFFSET * 2, height: 45)))
            topLabel.center = frontImage.center.applying(
                CGAffineTransform(translationX: self.view.frame.width * CGFloat(offset),
                                  y: (frontImage.frame.size.height / 2.0) + 50)
            )
            topLabel.translatesAutoresizingMaskIntoConstraints = true
            topLabel.font = self._TOP_FONT
            topLabel.text = self.strings[offset].0
            topLabel.textAlignment = .center
            
            let bottomLabel = UILabel(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.frame.width - 32, height: 32)))
            bottomLabel.center = topLabel.center.applying(
                CGAffineTransform(translationX: 0,
                                  y: (topLabel.frame.size.height / 2.0) + 20)
            )
            bottomLabel.font = self._BOTTOM_FONT
            bottomLabel.textColor = UIColor.lightGray
            bottomLabel.text = self.strings[offset].1
            bottomLabel.textAlignment = .center
            
            self.pages.append((topLabel, bottomLabel))
            self.view.addSubview(topLabel)
            self.view.addSubview(bottomLabel)
        })

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.panned))
        self.view.addGestureRecognizer(panGesture)
    }

    private var originalFrontTransform: CATransform3D = CATransform3D()
    private var originalBackTransform: CATransform3D = CATransform3D()
    private var originalLabelXpos: [(CGFloat, CGFloat)] = []
    private let animationDuration: Double = 0.4
    // location of your finger in relation to your starting pan location
    private var swipeLocation: Direction = .left
    @IBAction func panned(_ gestureRecognizer: UIPanGestureRecognizer) {
        //guard let pannedView = gestureRecognizer.view else { return }
        let translation = gestureRecognizer.translation(in: self.view)
        let percentage = translation.x/self.view.bounds.width
        let rotation = .pi * percentage
        let currentLocation: Direction = translation.x.sign == .minus ? .left : .right
        if gestureRecognizer.state == .began {
            self.originalFrontTransform = self.frontImage.layer.transform
            self.originalBackTransform = self.backImage.layer.transform
            self.originalLabelXpos = self.pages.map({ return ($0.0.layer.position.x, $0.1.layer.position.x)})
            self.swipeLocation = currentLocation
            switchBackImage(direction: self.swipeLocation)
            return
        }
        
        if self.swipeLocation != currentLocation {
            switchBackImage(direction: currentLocation)
            self.swipeLocation = currentLocation
        }
        // check for edges so that it goes in the right direction
        // e.g. can't go left when you're in the first page
        guard (percentage.sign == .minus && self.currentIndex < self.pages.count - 1) ||
            (percentage.sign == .plus && self.currentIndex > 0) else { return }

        if gestureRecognizer.state == .cancelled || gestureRecognizer.state == .ended {
            let xVelocity = gestureRecognizer.velocity(in: self.view).x
            let swipeDirection: Direction = xVelocity < 0 ? .left : .right
            //let percentage = self.swipeLocation != swipeDirection ? 1.0 - Double(percentage) : Double(percentage)
            finishAnimation(percentage: abs(Double(percentage)),
                            fingerLocation: self.swipeLocation,
                            fingerDirection: abs(xVelocity) > 10.0 ? swipeDirection : self.swipeLocation)
            return
        }
        zip(self.pages, self.originalLabelXpos).forEach({ element in
            let (topLabel, bottomLabel) = element.0
            let (origTopX, origBottomX) = element.1
            let factor: CGFloat = percentage.sign == .minus ? -1 : 1
            // move the top label at a faster rate, stopping at the resting position if the
            // pans more than necessary
            topLabel.layer.position.x = origTopX + (min((self.view.frame.width * CGFloat(abs(percentage))) * 1.2, self.view.frame.width) * factor)
            bottomLabel.layer.position.x = origBottomX + (self.view.frame.width * CGFloat(percentage))
        })

        self.frontImage.layer.transform = CATransform3DRotate(self.originalFrontTransform, rotation, 0, 1, 0)
        self.backImage.layer.transform = CATransform3DRotate(self.originalBackTransform, rotation, 0, 1, 0)

        // set opacity of the images
        // if the images are turned more than 50%, show the back image
        // if not, show the front image
        let opacity: Float = abs(percentage) < 0.50 ? 1.0 : 0.0
        self.frontImage.layer.opacity = opacity
        self.backImage.layer.opacity = opacity == 1.0 ? 0.0 : 1.0
    }
}

extension ViewController {
    private func switchBackImage(direction: Direction) {
        switch direction {
        case .left :
            self.backImage.image = self.images[min(self.currentIndex + 1, self.images.count - 1)]
        case .right:
            self.backImage.image = self.images[max(self.currentIndex - 1, 0)]
        }
    }
}

extension ViewController {

    private func finishAnimation(percentage: Double, fingerLocation: Direction, fingerDirection: Direction) {
        CATransaction.begin()
        
        let identity = CATransform3DIdentity
        let rotatePiTransform = CATransform3DRotate(identity, .pi, 0, 1, 0)
        
        let animationDuration = self.animationDuration * (1 - abs(percentage))

        let frontImageViewKeyframe = CAKeyframeAnimation(keyPath: "transform")
        let backImageViewKeyframe = CAKeyframeAnimation(keyPath: "transform")
        
        let changedMind: Bool = fingerLocation != fingerDirection
        
        var finalFrontImageTransform: CATransform3D = rotatePiTransform
        var finalBackImageTransform: CATransform3D = identity
        var nextIndexOffset = fingerDirection == .right ? -1 : 1
        var percentage: Double = Double(percentage)
        
        if changedMind {
            if (self.currentIndex == self.pages.endIndex - 1 && fingerDirection == .left) ||
                (self.currentIndex == self.pages.startIndex && fingerDirection == .right) {
                finalFrontImageTransform = identity
                finalBackImageTransform = rotatePiTransform
            }
            nextIndexOffset = 0
            percentage = 1.0 - Double(percentage)
        }
        // the page index that is going to be animated to
        let nextIndex = max(min(self.pages.index(before: self.pages.endIndex), self.currentIndex + nextIndexOffset), self.pages.startIndex)
        
        CATransaction.setCompletionBlock({ [weak self] in
            guard let strongSelf = self, !changedMind else { return }
            let intermediate = strongSelf.backImage
            strongSelf.backImage = strongSelf.frontImage
            strongSelf.frontImage = intermediate
            self?.currentIndex = nextIndex
        })
        
        if percentage > 0.5 {
            // Front Side
            frontImageViewKeyframe.values = [NSValue(caTransform3D: self.frontImage.layer.transform), NSValue(caTransform3D: finalFrontImageTransform)]
            frontImageViewKeyframe.keyTimes = [0.0, 1.0]

            // Back Side
            backImageViewKeyframe.values = [NSValue(caTransform3D: self.backImage.layer.transform), NSValue(caTransform3D: finalBackImageTransform)]
            backImageViewKeyframe.keyTimes = [0.0, 1.0]
        } else {
            let factor: CGFloat = fingerDirection == .right ? 1 : -1
            let halfWayTime = Float(0.5 - percentage)
            
            var initialFrontImageOpacity: Float = 1.0
            var finalFrontImageOpacity: Float = 0.0
            var initialBackImageOpacity: Float = 0.0
            var finalBackImageOpacity: Float = 1.0
            if changedMind {
                initialFrontImageOpacity = 0.0
                finalFrontImageOpacity = 1.0
                initialBackImageOpacity = 1.0
                finalBackImageOpacity = 0.0
            }

            // Front Side
            // animate the rotation
            var rotateHalfway = CATransform3DRotate(identity, factor * (CGFloat(.pi/2.0)), 0, 1, 0)
            frontImageViewKeyframe.values = [NSValue(caTransform3D: self.frontImage.layer.transform), NSValue(caTransform3D: rotateHalfway), NSValue(caTransform3D: rotateHalfway), NSValue(caTransform3D: finalFrontImageTransform)]
            frontImageViewKeyframe.keyTimes = [0, NSNumber(value: halfWayTime - 0.01), NSNumber(value: halfWayTime), 1.0]
            // animate the opacity so that it hides half way
            let alphaKeyFrame = CAKeyframeAnimation(keyPath: "opacity")
            alphaKeyFrame.values = [initialFrontImageOpacity, initialFrontImageOpacity, finalFrontImageOpacity, finalFrontImageOpacity]
            alphaKeyFrame.keyTimes = [0, NSNumber(value: halfWayTime - 0.01), NSNumber(value: halfWayTime), 1.0]
            self.frontImage.layer.opacity = finalFrontImageOpacity
            alphaKeyFrame.duration = animationDuration
            self.frontImage.layer.add(alphaKeyFrame, forKey: nil)

            // Back Side
            // animate the rotation
            rotateHalfway = CATransform3DRotate(identity, -1 * factor * (CGFloat(.pi/2.0)), 0, 1, 0)
            backImageViewKeyframe.values = [NSValue(caTransform3D: self.backImage.layer.transform), NSValue(caTransform3D: rotateHalfway),NSValue(caTransform3D: rotateHalfway), NSValue(caTransform3D: finalBackImageTransform)]
            backImageViewKeyframe.keyTimes = [0, NSNumber(value: halfWayTime - 0.01), NSNumber(value: halfWayTime), 1.0]
            // animate the opacity so that it shows half way
            let alphaBackKeyFrame = CAKeyframeAnimation(keyPath: "opacity")
            alphaBackKeyFrame.values = [initialBackImageOpacity, initialBackImageOpacity, finalBackImageOpacity, finalBackImageOpacity]
            alphaBackKeyFrame.keyTimes = [0, NSNumber(value: halfWayTime - 0.01), NSNumber(value: halfWayTime), 1.0]
            self.backImage.layer.opacity = finalBackImageOpacity
            alphaBackKeyFrame.duration = animationDuration
            self.backImage.layer.add(alphaBackKeyFrame, forKey: nil)
        }

        // Front Side
        frontImageViewKeyframe.duration = animationDuration
        self.frontImage.layer.transform = finalFrontImageTransform
        self.frontImage.layer.add(frontImageViewKeyframe, forKey: nil)

        // Back Side
        backImageViewKeyframe.duration = animationDuration
        self.backImage.layer.transform = finalBackImageTransform
        self.backImage.layer.add(backImageViewKeyframe, forKey: nil)

        // Label Animation
        for (index, labels) in self.pages.enumerated() {
            let nextX: CGFloat = (_LABEL_X_OFFSET + (CGFloat(index - nextIndex) * self.view.bounds.width)) + (labels.0.layer.bounds.width * labels.0.layer.anchorPoint.x)
            addLabelAnimations(currentLabels: labels, nextX: nextX, animationDuration: animationDuration)
        }
        CATransaction.commit()
    }

    
    private func addLabelAnimations(currentLabels: (UILabel, UILabel), nextX: CGFloat, animationDuration: Double) {
        let (thisTopLabel, thisBottomLabel) = currentLabels

        let topAnimation = CABasicAnimation(keyPath: "position.x")
        topAnimation.fromValue = thisTopLabel.layer.position.x
        topAnimation.toValue = nextX
        topAnimation.duration = animationDuration
        topAnimation.speed = 1.5
        thisTopLabel.layer.position.x = nextX
        thisTopLabel.layer.add(topAnimation, forKey: nil)

        let bottomAnimation = CABasicAnimation(keyPath: "position.x")
        bottomAnimation.fromValue = thisBottomLabel.layer.position.x
        bottomAnimation.toValue = nextX
        bottomAnimation.duration = animationDuration
        thisBottomLabel.layer.position.x = nextX
        thisBottomLabel.layer.add(bottomAnimation, forKey: nil)
    }
    
}



