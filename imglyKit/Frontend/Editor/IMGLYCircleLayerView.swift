//
//  IMGLYCircleLayerView.swift
//  imglyKit iOS
//
//  Created by Paresh Kanani on 30/11/20.
//  Copyright © 2020 9elements GmbH. All rights reserved.
//

import UIKit

class IMGLYCircleLayerView: UIView {

    var circleFrame: CGRect = .zero  {
        didSet {
            setNeedsLayout()
        }
    }
    
    var circleBounds: CGRect = .zero
    
    override var frame: CGRect {
        
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isOpaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isOpaque = false
    }

    override func draw(_ rect: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()
        
        UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.7).setFill()
        UIRectFill(rect)
        
        let circleSize = min(self.circleFrame.width, self.circleFrame.size.height) / 2
    
        let circle = UIBezierPath(arcCenter: CGPoint(x: rect.midX, y: rect.midY), radius: CGFloat(circleSize), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
        //print("BZ", circle.bounds)
        self.circleBounds = circle.bounds
        context?.setBlendMode(.clear)
        UIColor.clear.setFill()
        circle.fill()
        
    }
    
    //Allow touches through the circle crop cutter view
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews as [UIView] {
            if !subview.isHidden && subview.alpha > 0 && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }
    
    var circleInset: CGRect {
        let rect = bounds
        let minSize = min(rect.width, rect.height)
        let hole = CGRect(x: (rect.width - minSize) / 2, y: (rect.height - minSize) / 2, width: minSize, height: minSize).insetBy(dx: 5, dy: 5)
        return hole
    }

}
