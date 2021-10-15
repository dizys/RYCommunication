//
//  BKViewExtension.swift
//  BaseKit
//
//  Created by ldc on 2018/5/23.
//  Copyright © 2018年 Xiamen Hanin. All rights reserved.
//

import UIKit

public extension UIView {
    
    var width: CGFloat {
        
        set {
            bounds.size.width = newValue
        }
        
        get {
            return bounds.width
        }
    }
    
    var height: CGFloat {
        
        set {
            bounds.size.height = newValue
        }
        
        get {
            return bounds.height
        }
    }
}

public extension UIView {
    
    private static var swizzled = false
    
    private struct Key {
        static var TouchEdgeInsetKey = 0
    }
    //修改手势触发范围
    var touchEdgeInset: UIEdgeInsets? {
        
        get {
            return objc_getAssociatedObject(self, &Key.TouchEdgeInsetKey) as? UIEdgeInsets
        }
        
        set {
            objc_setAssociatedObject(self, &Key.TouchEdgeInsetKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    static func swizzlePointInsideMethod() {
        
        guard Thread.isMainThread else { return }
        if swizzled { return }
        
        swizzled = true
        
        if let origin = class_getInstanceMethod(self, #selector(point(inside:with:))),
            let new = class_getInstanceMethod(self, #selector(bk_point(inside:with:))) {
            method_exchangeImplementations(origin, new)
        }
    }
    
    @objc func bk_point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        
        if let inset = touchEdgeInset {
            let rect = bounds.insetBy(edgeInset: inset)
            return rect.contains(point)
        }else {
            return self.bk_point(inside: point, with: event)
        }
    }
}

public extension UIImageView {
    
    convenience init?(gifPath: String) {
        
        let url = URL.init(fileURLWithPath: gifPath)
        if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) {
            
            self.init(frame: .zero)
            let count = CGImageSourceGetCount(imageSource)
            if count <= 1 {
                if let imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) {
                    let image = UIImage.init(cgImage: imageRef)
                    self.image = image
                }
            }else {
                var images = [UIImage]()
                for i in 0..<count {
                    if let imageRef = CGImageSourceCreateImageAtIndex(imageSource, i, nil) {
                        images.append(UIImage.init(cgImage: imageRef))
                    }
                }
                self.image = images[0]
                self.animationImages = images
                self.animationDuration = TimeInterval(count)/30.0
            }
        }else {
            return nil
        }
    }
}
