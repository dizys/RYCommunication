//
//  AKConst.swift
//  BaseKit
//
//  Created by ldc on 2018/5/23.
//  Copyright © 2018年 Xiamen Hanin. All rights reserved.
//

import Foundation
import UIKit

public let WIDTH =  min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
public let HEIGHT = max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)

public var KeyWindow: UIWindow? {
    
    return  UIApplication.shared.keyWindow
}

public struct SandBox {
    
    public static let Documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
    public static let Cache = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
}

public func BKLog(_ item: Any?, file: String = #file, line: Int = #line) {
    
    #if DEBUG
    let fileName = (file as NSString).lastPathComponent
    print("\(fileName)-\(line):\n\(item ?? "nil")")
    #endif
}

public struct AppInfo {
    
    public static var version: String = { Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String }()
    
    public static var bundleId: String = { Bundle.main.infoDictionary!["CFBundleIdentifier"] as! String }()
    
    public static var displayName: String = { 
        Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String ?? Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? ""
    }()
}

public func openiPhoneSettings() -> Void {
    
    if let url = URL.init(string: "App-Prefs:root"), UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.openURL(url)
    }else if let url = URL.init(string: "Prefs:root"), UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.openURL(url)
    }
}
