//
//  BKAuthorizationExtension.swift
//  BaseKit
//
//  Created by ldc on 2018/9/5.
//  Copyright © 2018年 Xiamen Hanin. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import CoreBluetooth
import Photos

public extension AVCaptureDevice {
    
    static func requestCameraAuthorization(authorizedClosure: @escaping () -> Void) {
        
        let authorization = self.authorizationStatus(for: .video)
        switch authorization {
        case .authorized:
            authorizedClosure()
        case .denied:
            let message = String.init(format: "请在iPhone的\"设置-隐私-相机\"选项中，允许\"%@\"访问您的摄像头。".bk_localized, AppInfo.displayName)
            KeyWindow?.rootViewController?.bk_presentDecisionAlertController(title: "提示".bk_localized, message: message, decisionTitle: "去设置".bk_localized, decisionClosure: { (_) in
                guard let url = URL.init(string: UIApplication.openSettingsURLString) else { return }
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }else {
                    UIApplication.shared.openURL(url)
                }
            })
        case .restricted:
            let message = String.init(format: "手机摄像头功能受限".bk_localized, AppInfo.displayName)
            KeyWindow?.rootViewController?.bk_presentWarningAlertController(title: "提示".bk_localized, message: message, style: .destructive, closure: nil)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (authored) in
                if authored {
                    DispatchQueue.main.async {
                        authorizedClosure()
                    }
                }
            })
        @unknown default:
            fatalError("never execute")
        }
    }
}

public extension PHPhotoLibrary {
    
    static func requestPhotoAuthorization(authorizedClosure: @escaping () -> Void) {
        
        let authorization = PHPhotoLibrary.authorizationStatus()
        switch authorization {
        case .authorized, .limited:
            authorizedClosure()
        case .denied:
            let message = String.init(format: "请在iPhone的\"设置-隐私-照片\"选项中，允许\"%@\"访问您的相册。".bk_localized, AppInfo.displayName)
            KeyWindow?.rootViewController?.bk_presentDecisionAlertController(title: "提示".bk_localized, message: message, decisionTitle: "去设置".bk_localized, decisionClosure: { (_) in
                guard let url = URL.init(string: UIApplication.openSettingsURLString) else { return }
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }else {
                    UIApplication.shared.openURL(url)
                }
            })
        case .restricted:
            let message = String.init(format: "手机相册功能受限".bk_localized, AppInfo.displayName)
            KeyWindow?.rootViewController?.bk_presentWarningAlertController(title: "提示".bk_localized, message: message, style: .destructive, closure: nil)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (status) in
                DispatchQueue.main.async {
                    if status == .authorized {
                        authorizedClosure()
                    }
                }
            })
        @unknown default:
            fatalError("never execute")
        }
    }
}

public class BKBluetoothAuthorization: NSObject {
    
    public static var share = BKBluetoothAuthorization()
    
    private override init() {}
    
    private lazy var manager: CBCentralManager = {
        let temp = CBCentralManager.init(delegate: nil, queue: nil, options: nil)
        return temp
    }()
    private var closure: (() -> Void)?
    
    public func request(closure: @escaping () -> Void) {
        
        let status = manager.state
        switch status {
        case .poweredOn:
            closure()
        case .unknown, .resetting:
            self.closure = closure
            manager.delegate = self
        case .poweredOff:
            KeyWindow?.rootViewController?.bk_presentDecisionAlertController(title: "提示".bk_localized, message: "蓝牙不可用,请在\"设置-蓝牙\"中打开蓝牙并允许新连接".bk_localized, decisionTitle: "去设置".bk_localized, decisionClosure: { _ in
                openiPhoneSettings()
            })
        case .unauthorized:
            KeyWindow?.rootViewController?.bk_presentDecisionAlertController(title: "提示".bk_localized, message: String.init(format: "去iPhone的\"设置-隐私-蓝牙\"中，允许\"%@\"使用蓝牙".bk_localized, AppInfo.displayName), decisionTitle: "去设置".bk_localized, decisionClosure: { _ in
                UIApplication.shared.openURL(URL.init(string: UIApplication.openSettingsURLString)!)
            })
        case .unsupported:
            KeyWindow?.rootViewController?.bk_presentWarningAlertController(title: "提示".bk_localized, message: "您的iPhone暂不支持使用蓝牙".bk_localized)
        @unknown default:
            break
        }
    }
}

extension BKBluetoothAuthorization: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .poweredOn:
            self.manager.delegate = nil
            closure?()
            closure = nil
        case .unknown, .resetting:
            break
        case .poweredOff:
            KeyWindow?.rootViewController?.bk_presentDecisionAlertController(title: "提示".bk_localized, message: "蓝牙不可用,请在\"设置-蓝牙\"中打开蓝牙并允许新连接".bk_localized, decisionTitle: "去设置".bk_localized, decisionClosure: { _ in
                openiPhoneSettings()
            })
        case .unauthorized:
            KeyWindow?.rootViewController?.bk_presentDecisionAlertController(title: "提示".bk_localized, message: String.init(format: "去iPhone的\"设置-隐私-蓝牙\"中，允许\"%@\"使用蓝牙".bk_localized, AppInfo.displayName), decisionTitle: "去设置".bk_localized, decisionClosure: { _ in
                UIApplication.shared.openURL(URL.init(string: UIApplication.openSettingsURLString)!)
            })
        case .unsupported:
            KeyWindow?.rootViewController?.bk_presentWarningAlertController(title: "提示".bk_localized, message: "您的iPhone暂不支持使用蓝牙".bk_localized)
        @unknown default:
            break
        }
        self.manager.delegate = nil
        closure = nil
    }
}
