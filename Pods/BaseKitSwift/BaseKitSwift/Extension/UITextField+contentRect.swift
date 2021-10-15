//
//  UITextFieldExtension.swift
//  BaseKit
//
//  Created by ldc on 2019/5/17.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

import UIKit

public extension UITextField {
    
    private static var swizzled = false
    
    static func bk_swizzle() {
        
        guard Thread.isMainThread else { return }
        if swizzled { return }
        
        swizzled = true
        let originSelectors = [
            #selector(self.leftViewRect(forBounds:)),
            #selector(self.textRect(forBounds:)),
            #selector(self.editingRect(forBounds:))
        ]
        let newSelectors = [
            #selector(self.bk_leftViewRect(forBounds:)),
            #selector(self.bk_textRect(forBounds:)),
            #selector(self.bk_editingRect(forBounds:))
        ]
        
        for i in 0..<originSelectors.count {
            
            if let originMethod = class_getInstanceMethod(self, originSelectors[i]), let newMethod = class_getInstanceMethod(self, newSelectors[i]) {
                method_exchangeImplementations(originMethod, newMethod)
            }
        }
    }
    
    fileprivate struct Key {
        
        static var leftViewRectKey = 0
        static var horizonalTextMargin = 0
    }
    
    var leftViewRect: CGRect? {
        
        set {
            objc_setAssociatedObject(self, &Key.leftViewRectKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
        
        get {
            return objc_getAssociatedObject(self, &Key.leftViewRectKey) as? CGRect
        }
    }
    
    var horizonalTextMargin: CGFloat? {
        
        set {
            objc_setAssociatedObject(self, &Key.horizonalTextMargin, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
        
        get {
            return objc_getAssociatedObject(self, &Key.horizonalTextMargin) as? CGFloat
        }
    }
    
    @objc func bk_leftViewRect(forBounds bounds: CGRect) -> CGRect {
        
        if let leftViewRect = leftViewRect {
            return leftViewRect
        }else {
            return bk_leftViewRect(forBounds: bounds)
        }
    }
    
    @objc func bk_textRect(forBounds bounds: CGRect) -> CGRect {
        
        if let horizonalTextMargin = horizonalTextMargin {
            
            var rect = bk_textRect(forBounds: bounds)
            rect.origin.x += horizonalTextMargin
            switch clearButtonMode {
            case .always,
                 .unlessEditing:
                rect.size.width -= horizonalTextMargin
            default:
                rect.size.width -= 2*horizonalTextMargin
            }
            return rect
        }else {
            return bk_textRect(forBounds: bounds)
        }
    }
    
    @objc func bk_editingRect(forBounds bounds: CGRect) -> CGRect {
        
        if let horizonalTextMargin = horizonalTextMargin {
            
            var rect = bk_editingRect(forBounds: bounds)
            rect.origin.x += horizonalTextMargin
            switch clearButtonMode {
            case .whileEditing,
                 .always:
                rect.size.width -= horizonalTextMargin
            default:
                rect.size.width -= 2*horizonalTextMargin
            }
            return rect
        }else {
            return bk_editingRect(forBounds: bounds)
        }
    }
}
