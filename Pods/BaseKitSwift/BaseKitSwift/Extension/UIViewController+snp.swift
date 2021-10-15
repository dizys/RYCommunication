//
//  BKVIewControllerExtension.swift
//  BaseKit
//
//  Created by ldc on 2018/5/23.
//  Copyright © 2018年 Xiamen Hanin. All rights reserved.
//

import UIKit
import SnapKit

public extension UIViewController {
    
    var width: CGFloat {
        
        set {
            view.bounds.size.width = newValue
        }
        
        get {
            return view.bounds.width
        }
    }
    
    var height: CGFloat {
        
        set {
            view.bounds.size.height = newValue
        }
        
        get {
            return view.bounds.height
        }
    }
}

public extension UIViewController {
    
    private static var CustomGuideKey = 0
    
    @available(iOS 9.0, *)
    private var bk_custom_guide: UILayoutGuide {
        
        return getCustomGuide()
    }
    
    @available(iOS 9.0, *)
    private func getCustomGuide() -> UILayoutGuide {
        
        if #available(iOS 11, *) {
            return view!.safeAreaLayoutGuide
        }else {
            if let temp = objc_getAssociatedObject(self, &UIViewController.CustomGuideKey) as? UILayoutGuide {
                return temp
            }else {
                let guide = UILayoutGuide()
                view.addLayoutGuide(guide)
                guide.snp.makeConstraints({ (maker) in
                    maker.left.equalTo(view.snp.left)
                    maker.right.equalTo(view.snp.right)
                    maker.top.equalTo(self.topLayoutGuide.snp.bottom)
                    maker.bottom.equalTo(self.bottomLayoutGuide.snp.top)
                })
                objc_setAssociatedObject(self, &UIViewController.CustomGuideKey, guide, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return guide
            }
        }
    }
    
    var snp: ConstraintAttributesDSL {

        if #available(iOS 9, *) {
            return bk_custom_guide.snp
        }else {
            return view.snp
        }
    }
    
    var safeAreaInsets: UIEdgeInsets {
        
        if #available(iOS 11, *) {
            return view.safeAreaInsets
        }else {
            return .zero
        }
    }
}

fileprivate weak var AlertController: UIAlertController?

public extension UIViewController {
    
    func bk_presentAlertController(
        title: String?,
        message: String?,
        preferredStyle: UIAlertController.Style,
        actions: [UIAlertAction])
        -> Void
    {
        
        let closure = { () in
            let temp = UIAlertController.init(title: title, message: message, preferredStyle: preferredStyle)
            for action in actions {
                temp.addAction(action)
            }
            temp.popoverPresentationController?.sourceView = self.view
            temp.popoverPresentationController?.sourceRect = CGRect.init(x: 0, y: self.view.height/2, width: self.view.width, height: 1)
            self.present(temp, animated: true, completion: nil)
            AlertController = temp
        }
        if let alert = AlertController, let _ = alert.presentingViewController {
            
            alert.dismiss(animated: true, completion: closure)
        }else {
            closure()
        }
    }
    
    func bk_presentWarningAlertController(
        title: String,
        message: String,
        style: UIAlertAction.Style = .default,
        closure: ((UIAlertAction) -> Void)? = nil)
        -> Void
    {
        
        let action = UIAlertAction.init(title: "确定".bk_localized, style: style, handler: closure)
        bk_presentAlertController(title: title, message: message, preferredStyle: .alert, actions: [action])
    }
    
    func bk_presentDecisionAlertController(
        title: String?,
        message: String?,
        decisionTitle: String?,
        decisionClosure: @escaping (UIAlertAction) -> Void,
        cancelClosure: ((UIAlertAction) -> Void)? = nil)
        -> Void
    {
        
        let action1 = UIAlertAction.init(title: decisionTitle ?? "确定".bk_localized, style: .default, handler: decisionClosure)
        let action2 = UIAlertAction.init(title: "取消".bk_localized, style: .cancel, handler: cancelClosure)
        bk_presentAlertController(title: title, message: message, preferredStyle: .alert, actions: [action1, action2])
    }
}

