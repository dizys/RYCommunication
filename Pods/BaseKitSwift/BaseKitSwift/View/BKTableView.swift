//
//  BKTableView.swift
//  BaseKitSwift
//
//  Created by ldc on 2020/5/11.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

import UIKit

public class BKTableView: UITableView {
    
    /// 如果bk_placeholderView为空，将使用这个closure生成占位图
    public static var placeholderViewClosure: (() -> UIView)?
    
    /// 对象的独特占位图
    public var placeholderView: UIView?
    
    public override func removeFromSuperview() {
        removeObserver(self, forKeyPath: "contentSize")
        super.removeFromSuperview()
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview != nil {
            addObserver(self, forKeyPath: "contentSize", options: [.new], context: nil)
        }
        super.willMove(toSuperview: newSuperview)
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath, keyPath == "contentSize" {
            for i in 0..<numberOfSections {
                if numberOfRows(inSection: i) != 0 {
                    backgroundView = nil
                    return
                }
            }
            if let background = self.placeholderView {
                backgroundView = background
            }else {
                backgroundView = BKTableView.placeholderViewClosure?()
            }
        }
    }
}
