//
//  UD.swift
//  BaseKitSwift
//
//  Created by ldc on 2019/7/12.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

import Foundation

public protocol UD {
    
    associatedtype ValueType
    
    var namespace: String { get }
    
    func save(_ value: Self.ValueType?) -> Void
    
    var value: Self.ValueType? { get }
    
}

public extension UD {
    
    var namespace: String {
        
        #if DEBUG
        return "\(type(of: self)).\(self)"
        #else
        return "\(type(of: self)).\(self)".md5
        #endif
    }
    
    func save(_ value: Self.ValueType?) -> Void {
        
        UserDefaults.standard.set(value, forKey: namespace)
        UserDefaults.standard.synchronize()
    }
    
    var value: Self.ValueType? {
        
        return UserDefaults.standard.value(forKey: namespace) as? Self.ValueType
    }
}
