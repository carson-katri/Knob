//
//  Knob.swift
//  Knob
//
//  Created by Chris Gulley on 9/10/15.
//  Copyright © 2015 Chris Gulley. All rights reserved.
//

import UIKit

/**
 * Return vector from lhs point to rhs point.
 */
func - (lhs: CGPoint, rhs: CGPoint) -> CGVector {
    return CGVector(dx: rhs.x - lhs.x, dy: rhs.y - lhs.y)
}

extension CGVector {
    /**
     * Returns angle between vector and receiver in radians. Return is between
     * 0 and 2 * PI in counterclockwise direction.
     */
    func angleFromVector(vector: CGVector) -> Double {
        let angle = Double(atan2(-dy, dx) - atan2(-vector.dy, vector.dx))
        return angle > 0 ? angle : angle + 2 * M_PI
    }
}

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
    }
}

extension UIColor {
    /**
     * Returns a color with adjusted saturation and brigtness than can be used to
     * indicate control is disabled.
     */
    func disabledColor() -> UIColor {
        var h = CGFloat(0)
        var s = CGFloat(0)
        var b = CGFloat(0)
        var a = CGFloat(0)
        
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s * 0.5, brightness: b * 1.2, alpha: a)
    }
}

extension CATransaction {
    static func doWithNoAnimation(action:()->Void) {
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        action()
        CATransaction.commit()
    }
}

/**
 * A Knob object is a visual control used to select a value from a range of values between
 * 0 and 2 * PI radians. A user rotates the control using a single figure pan gesture with
 * values increasing as the knob is rotated clockwise. The value resets from 2 * PI to 0 as
 * the user rotates the knob through the 12 o'clock position.
 */
public class Knob: UIControl {
    private let indicatorLayer = CAShapeLayer()
    private let lineWidth = CGFloat(1)
    private var lastVector = CGVector.zero
    private var angle = M_PI / 2.0
    
    /**
     * Contains the current value.
     */
    public var value: Float {
        get {
            return (Float(5 * M_PI / 2) - Float(angle)) % Float(2 * M_PI)
        }
        set {
            angle = (5 * M_PI / 2 - Double(newValue)) % (2 * M_PI)
            updateLayer()
        }
    }
    
    override public var frame: CGRect {
        didSet {
            CATransaction.doWithNoAnimation {
                self.updateLayer()
            }
        }
    }
    
    override public var enabled: Bool {
        didSet {
            CATransaction.doWithNoAnimation {
                self.updateLayer()
            }
        }
    }
    
    private var knobBackgroundColor: UIColor?
    override public var backgroundColor: UIColor? {
        get {
           return knobBackgroundColor
        }
        
        set {
            knobBackgroundColor = newValue
            updateLayer()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        updateLayer()
    }
    
    required public init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        updateLayer()
    }
    
    private func updateLayer() {
        let shapeLayer = layer as! CAShapeLayer
        if let color = knobBackgroundColor {
            shapeLayer.fillColor = enabled ? color.CGColor : (color.disabledColor().CGColor)
        }
        else {
            shapeLayer.fillColor = UIColor.clearColor().CGColor
        }
        shapeLayer.backgroundColor = UIColor.clearColor().CGColor
        shapeLayer.strokeColor = enabled ? tintColor.CGColor : (tintColor.disabledColor().CGColor)
        shapeLayer.lineWidth = lineWidth
        
        // Adjust drawing rectangle for line width
        var dx = shapeLayer.lineWidth / 2, dy = shapeLayer.lineWidth / 2
        
        // Draw perfect circle even if view is rectangular
        if bounds.width > bounds.height {
            dx += (bounds.width - bounds.height) / 2
        }
        else if bounds.height > bounds.width {
            dy += (bounds.height - bounds.width) / 2
        }
        let ovalRect = bounds.insetBy(dx: dx, dy: dy)
        shapeLayer.path = UIBezierPath(ovalInRect: ovalRect).CGPath
        
        // Adjust for line width to keep tick mark inside circle
        let shortSide = min(bounds.width, bounds.height)
        indicatorLayer.bounds = CGRect(x: 0, y: 0, width: shortSide - 2 * lineWidth, height: shortSide - 2 * lineWidth)
        
        updateIndicator()
        
        indicatorLayer.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        indicatorLayer.lineWidth = shapeLayer.lineWidth
        indicatorLayer.strokeColor = shapeLayer.strokeColor
        indicatorLayer.fillColor = UIColor.clearColor().CGColor
        
        shapeLayer.addSublayer(indicatorLayer)
    }
    
    /**
     * Draw value indicator, usually in response to the value changing.
     */
    private func updateIndicator() {
        let linePath = UIBezierPath()
        
        let center = indicatorLayer.bounds.center
        let cosA = CGFloat(cos(angle))
        let sinA = CGFloat(sin(angle))
        
        let x1 = center.x + (indicatorLayer.bounds.width / 2) * cosA
        let y1 = center.y - (indicatorLayer.bounds.height / 2) * sinA
        linePath.moveToPoint(CGPoint(x:x1, y:y1))

        let x2 = center.x + (indicatorLayer.bounds.width / 3) * cosA
        let y2 = center.y - (indicatorLayer.bounds.height / 3) * sinA
        linePath.addLineToPoint(CGPoint(x:x2, y:y2))
        
        indicatorLayer.path = linePath.CGPath
    }
    
    override public func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        lastVector = touch.locationInView(self.superview) - center
        return true
    }
    
    override public func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        // Calculate vector from center to touch.
        let vector = touch.locationInView(self.superview) - center
        
        // Add angular difference to our current value.
        angle = (angle + vector.angleFromVector(lastVector)) % (2 * M_PI)
        lastVector = vector
        updateIndicator()
        
        sendActionsForControlEvents(UIControlEvents.ValueChanged)
        
        return true
    }
    
    public override class func layerClass() -> AnyClass {
        return CAShapeLayer.self
    }
}
