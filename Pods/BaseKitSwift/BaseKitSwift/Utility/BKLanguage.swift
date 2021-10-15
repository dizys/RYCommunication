//
//  BKLanguage.swift
//  BaseKitSwift
//
//  Created by ldc on 2020/6/2.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

import Foundation

public class BKLanguage: NSObject {
    
    public enum `Type`: String, Equatable, CustomStringConvertible {
        case en, hans, hant, ja
        
        public var description: String {
            
            switch self {
            case .en:
                return "en"
            case .hans:
                return "zh-cn"
            case .hant:
                return "tc"
            case .ja:
                return "jp"
            }
        }
    }
    
    public static var current: Type {
        
        let preferredLang = (Bundle.main.preferredLocalizations.first! as NSString)
        if preferredLang.hasPrefix("zh") {
            if preferredLang.hasPrefix("zh-Hant") {
                return .hant
            }else {
                //zh-Hans
                return .hans
            }
        }else if preferredLang.hasPrefix("ja") {
            return .ja
        }else {
            return .en
        }
    }
}
