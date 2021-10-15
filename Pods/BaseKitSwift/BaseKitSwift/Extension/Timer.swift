//
//  Timer.swift
//  BaseKitSwift
//
//  Created by ldc on 2020/8/20.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

import Foundation

public extension Timer {
    
    private struct Key {
        static var block = 0
        static var deadline = 0
    }
    
    private var closure: ((Timer) -> Void)? {
        
        set {
            objc_setAssociatedObject(self, &Key.block, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
        
        get {
            return objc_getAssociatedObject(self, &Key.block) as? (Timer) -> Void
        }
    }
    
    private var deadline: TimeInterval {
        
        set {
            objc_setAssociatedObject(self, &Key.deadline, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        get {
            return objc_getAssociatedObject(self, &Key.deadline) as? TimeInterval ?? 0
        }
    }
    
    @objc static func timerClosure(timer: Timer) {
        
        if let closure = timer.closure {
            timer.deadline -= timer.timeInterval
            if timer.isValid && timer.deadline <= 0 {
                timer.bk_invalidate()
            }
            closure(timer)
        }else {
            timer.bk_invalidate()
        }
    }
    
    @discardableResult
    static func timer(_ interval: TimeInterval, repeatCount: Int = 1, block: @escaping (Timer) -> Void) -> Timer {
        
        let timer = scheduledTimer(timeInterval: interval, target: self, selector: #selector(self.timerClosure(timer:)), userInfo: nil, repeats: true)
        timer.deadline = interval*TimeInterval(repeatCount)
        timer.closure = block
        return timer
    }
    
    func bk_invalidate() -> Void {
        
        closure = nil
        deadline = 0
        invalidate()
    }
}
