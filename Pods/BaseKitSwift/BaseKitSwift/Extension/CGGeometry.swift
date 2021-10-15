//
//  BKGeometryExtension.swift
//  BaseKit
//
//  Created by ldc on 2018/6/6.
//  Copyright © 2018年 Xiamen Hanin. All rights reserved.
//

import UIKit

public extension CGRect {
    
    func contentRect(ratio: CGFloat, margin: CGFloat = 0) -> CGRect {
        
        let tempFrame = self.insetBy(dx: margin, dy: margin)
        if tempFrame.width/tempFrame.height > ratio {
            
            let contentWidth = ratio*tempFrame.height
            let result = tempFrame.insetBy(dx: (tempFrame.width - contentWidth)/2, dy: 0)
            return result
        }else {
            
            let contentHeight = tempFrame.width/ratio
            let result = tempFrame.insetBy(dx: 0, dy: (tempFrame.height - contentHeight)/2)
            return result
        }
    }
    
    func insetBy(edgeInset: UIEdgeInsets) -> CGRect {
        
        return CGRect.init(
            x: self.origin.x + edgeInset.left,
            y: self.origin.y + edgeInset.top,
            width: self.size.width - edgeInset.left - edgeInset.right,
            height: self.size.height - edgeInset.top - edgeInset.bottom
        )
    }
}

public func + (lhs: CGRect, rhs: CGRect) -> CGRect {
    
    return CGRect.init(
        x: lhs.origin.x + rhs.origin.x,
        y: lhs.origin.y + rhs.origin.y,
        width: lhs.size.width + rhs.size.width,
        height: lhs.size.height + rhs.size.height
    )
}

public func * (rect: CGRect, scale: CGFloat) -> CGRect {
    
    return CGRect.init(
        x: rect.origin.x*scale,
        y: rect.origin.y*scale,
        width: rect.width*scale,
        height: rect.height*scale
    )
}

public func / (rect: CGRect, divided: CGFloat) -> CGRect {
    
    return CGRect.init(
        x: rect.origin.x/divided,
        y: rect.origin.y/divided,
        width: rect.width/divided,
        height: rect.height/divided
    )
}

public func * (size: CGSize, scale: CGFloat) -> CGSize {
    
    return CGSize.init(width: size.width*scale, height: size.height*scale)
}

public func / (size: CGSize, divided: CGFloat) -> CGSize {
    
    return CGSize.init(width: size.width/divided, height: size.height/divided)
}

public func * (inset: UIEdgeInsets, scale: CGFloat) -> UIEdgeInsets {
    
    return UIEdgeInsets.init(
        top: inset.top*scale,
        left: inset.left*scale,
        bottom: inset.bottom*scale,
        right: inset.right*scale
    )
}

public func / (inset: UIEdgeInsets, divided: CGFloat) -> UIEdgeInsets {
    
    return UIEdgeInsets.init(
        top: inset.top/divided,
        left: inset.left/divided,
        bottom: inset.bottom/divided,
        right: inset.right/divided
    )
}

public func / (point: CGPoint, divided: CGFloat) -> CGPoint {
    
    return CGPoint.init(x: point.x/divided, y: point.y/divided)
}

public func * (point: CGPoint, scale: CGFloat) -> CGPoint {
    
    return CGPoint.init(x: point.x*scale, y: point.y*scale)
}

public extension CGSize {
    
    var ratio: CGFloat {
        
        return width/height
    }
}

public extension CGAffineTransform {
    
    /// 要求变换矩阵不包含缩放分量
    var rotate: CGFloat { return atan2(b, a) }
    
    /// 要求变换矩阵不包含旋转分量
    var scaleX: CGFloat { return sqrt(a*a+c*c) }
    
    var scaleY: CGFloat { return sqrt(b*b+d*d) }
    
    var translateX: CGFloat { return tx }
    
    var translateY: CGFloat { return ty }
}
