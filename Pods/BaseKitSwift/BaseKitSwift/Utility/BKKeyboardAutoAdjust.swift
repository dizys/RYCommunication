//
//  BKKeyboardAutoAdjust.swift
//  SwiftTest
//
//  Created by ldc on 2018/9/17.
//  Copyright © 2018年 Xiamen Hanin. All rights reserved.
//

import UIKit

public class BKKeyboardAutoAdjust: NSObject {

    private var editingViewFrame = CGRect.zero
    
    public static let share = BKKeyboardAutoAdjust()
    
    fileprivate override init() {
        super.init()
    }
    
    public func beginMonitoredEditing(){
        
        let items: [(Selector, Notification.Name)] = [
            (#selector(self.keyboardWillShow(notify:)), UIResponder.keyboardWillShowNotification),
            (#selector(self.textFieldDidBeginEditing(notify:)), UITextField.textDidBeginEditingNotification),
            (#selector(self.keyboardWillHide(notify:)), UIResponder.keyboardWillHideNotification),
        ]
        for item in items {
            NotificationCenter.default.addObserver(self, selector: item.0, name: item.1, object: nil)
        }
    }
    
    public func stopMonitoredEditing() -> Void {
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(notify: Notification) {
        
        guard let value = notify.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let frame = value.cgRectValue
        if frame.intersects(self.editingViewFrame) {
            UIView.animate(withDuration: 0.25) { 
                UIApplication.shared.keyWindow?.frame = CGRect.init(x: 0, y: frame.minY - self.editingViewFrame.maxY, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            }
        }
    }
    
    @objc func keyboardWillHide(notify: Notification) {
        
        self.editingViewFrame = .zero
        UIView.animate(withDuration: 0.25) { 
            UIApplication.shared.keyWindow?.frame = UIScreen.main.bounds
        }
    }
    
    @objc func textFieldDidBeginEditing(notify: Notification) {
        
        guard let textField = notify.object as? UITextField else { return }
        guard let superView = textField.superview else { return }
        guard let frame = UIApplication.shared.keyWindow?.convert(textField.frame, from: superView) else { return }
        self.editingViewFrame = frame
    }
    
}
