//
//  CP4000LBleCmdGenerator.swift
//  Example
//
//  Created by ldc on 2020/9/10.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

import Foundation
import RYCommunication
import BaseKitSwift

class CP4000LWiFiModeInfo {
    
    enum WiFiMode: CustomStringConvertible {
        case sta, ap
        
        var description: String {
            
            switch self {
            case .sta:
                return "STA"
            case .ap:
                return "AP"
            }
        }
    }
    
    let mode: WiFiMode
    let ssid: String
    let password: String
    let security: String
    let ip: String?
    
    init?(with data: Data) {
        
        var pos = 0
        let count = data.count
        guard count > pos + 1 else {
            return nil
        }
        pos += 1
        let ssidCount = Int(data[pos])
        pos += 1
        guard count > pos + ssidCount else {
            return nil
        }
        let ssidData = ssidCount > 0 ? data[pos...pos+ssidCount-1] : Data()
        pos += ssidCount
        let securityDataCount = Int(data[pos])
        pos += 1
        guard count > pos + securityDataCount else {
            return nil
        }
        let securityData = securityDataCount > 0 ? data[pos...pos+securityDataCount-1] : Data()
        pos += securityDataCount
        let passwordDataCount = Int(data[pos])
        pos += 1
        guard count > pos + passwordDataCount - 1 else {
            return nil
        }
        let passwordData = passwordDataCount > 0 ? data[pos...pos+passwordDataCount-1] : Data()
        pos += passwordDataCount
        
        mode = data[0] == 1 ? .sta : .ap
        ssid = String.init(data: ssidData, encoding: .utf8)!
        security = String.init(data: securityData, encoding: .ascii)!
        password = String.init(data: passwordData, encoding: .ascii)!
        guard count > pos else {
            ip = nil
            return
        }
        let ipDataCount = Int(data[pos])
        pos += 1
        guard count > pos + ipDataCount - 1 else {
            ip = nil
            return
        }
        let ipData = ipDataCount > 0 ? data[pos...pos+ipDataCount-1] : Data()
        ip = String.init(data: ipData, encoding: .ascii)!
    }
}

class CP4000LBleCmdGenerator: CmdGenerator {
    
    var accessory: RYAccessory
    
    var samples: [ActionItem] = []
    
    init(with accessory: RYAccessory) {
        self.accessory = accessory
        initResolver()
        initSamples()
    }
    
    private func initResolver() {
        
        self.accessory.resolver = CP4000LikeBluetoothResolver()
        self.accessory.resolver?.resolvedBlock = {
            let model = $0 as! CP4000LikeBluetoothResolver.Model
            switch model.type {
            case .sn:
                let content = model.data
                if let temp = String.init(data: content, encoding: .ascii) {
                    KeyWindow?.rootViewController?.bk_presentWarningAlertController(title: "接收消息", message: "hex: \(model.rawData.hexString)\nsn: \(temp)", style: .default)
                }else {
                    KeyWindow?.rootViewController?.bk_presentWarningAlertController(title: "接收消息", message: "hex: \(model.rawData.hexString)", style: .default)
                }
            case .firmwareVersion:
                let content = model.data
                if content.count >= 3 {
                    let temp = content[0...2].map({ String.init(format: "%i", $0) }).reversed().joined(separator: ".")
                    KeyWindow?.rootViewController?.bk_presentWarningAlertController(title: "接收消息", message: "hex: \(model.rawData.hexString)\n固件版本: \(temp)", style: .default)
                }else {
                    KeyWindow?.rootViewController?.bk_presentWarningAlertController(title: "接收消息", message: "hex: \(model.rawData.hexString)", style: .default)
                }
            case .staIp:
                let content = model.data
                if let temp = String.init(data: content, encoding: .ascii) {
                    KeyWindow?.rootViewController?.bk_presentWarningAlertController(title: "接收消息", message: "hex: \(model.rawData.hexString)\nSTA IP: \(temp)", style: .default)
                }else {
                    KeyWindow?.rootViewController?.bk_presentWarningAlertController(title: "接收消息", message: "hex: \(model.rawData.hexString)", style: .default)
                }
            case .configuerWifi:
                let flag = model.data[0]
                let ip: String
                if model.data.count > 1 {
                    ip = String.init(data: Data(model.data[1...model.data.count-1]), encoding: .ascii) ?? "nil"
                }else {
                    ip = "nil"
                }
                if flag == 1 {
                    KeyWindow?.rootViewController?.bk_presentWarningAlertController(title: "接收消息", message: "hex: \(model.rawData.hexString)\n配网: 成功\nIP: \(ip)", style: .default)
                }else {
                    KeyWindow?.rootViewController?.bk_presentWarningAlertController(title: "接收消息", message: "hex: \(model.rawData.hexString)\n配网: 失败\nIP: \(ip)", style: .default)
                }
            case .resetToAP:
                let flag = model.data[0]
                let ssid: String
                if model.data.count > 1 {
                    ssid = String.init(data: Data(model.data[1...model.data.count-1]), encoding: .ascii) ?? "nil"
                }else {
                    ssid = "nil"
                }
                if flag == 1 {
                    KeyWindow?.rootViewController?.bk_presentWarningAlertController(title: "接收消息", message: "hex: \(model.rawData.hexString)\n切换AP模式: 成功\nSSID: \(ssid)", style: .default)
                }else {
                    KeyWindow?.rootViewController?.bk_presentWarningAlertController(title: "接收消息", message: "hex: \(model.rawData.hexString)\n切换AP模式: 失败\nSSID: \(ssid)", style: .default)
                }
            case .wifiMode:
                if let temp = CP4000LWiFiModeInfo.init(with: model.data) {
                    if let ip = temp.ip {
                        KeyWindow?.rootViewController?.bk_presentWarningAlertController(title: "接收消息", message: "hex: \(model.rawData.hexString)\nWi-Fi模式: \(temp.mode)\nssid: \(temp.ssid)\n加密方式:\(temp.security)\n密码: \(temp.password)\nip:\(ip)", style: .default)
                    }else {
                        KeyWindow?.rootViewController?.bk_presentWarningAlertController(title: "接收消息", message: "hex: \(model.rawData.hexString)\nWi-Fi模式: \(temp.mode)\nssid: \(temp.ssid)\n加密方式:\(temp.security)\n密码: \(temp.password)", style: .default)
                    }
                }else {
                    KeyWindow?.rootViewController?.bk_presentWarningAlertController(title: "接收消息", message: "hex: \(model.rawData.hexString)", style: .default)
                }
            default:
                break
            }
        }
    }
    
    private func initSamples() {
        
        var item: ActionItem
        item = ActionItem.init(title: "获取SN", action: { [unowned self] in
            let cmd = CP4000LikeBluetoothCommand.regularCmd(type: .sn, content: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(item)
        
        item = ActionItem.init(title: "重置Wi-Fi至AP模式", action: { [unowned self] in
            let cmd = CP4000LikeBluetoothCommand.regularCmd(type: .resetToAP, content: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(item)
        
        item = ActionItem.init(title: "获取Wi-Fi模式", action: { [unowned self] in
            let cmd = CP4000LikeBluetoothCommand.regularCmd(type: .wifiMode, content: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(item)
        
        item = ActionItem.init(title: "固件版本", action: { [unowned self] in
            let cmd = CP4000LikeBluetoothCommand.regularCmd(type: .firmwareVersion, content: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(item)
    }
}

class CP4000LikeBluetoothCommand {
    
    //数据格式 数据头00(1字节) + 类型(1字节) + 数据长度(1字节) + 数据
    //数据可拼接发送 
    //数据类型 0 Wi-Fi名称 1 Wi-Fi密码 2 密码加密方式
    
    struct ResolveModel {
        var cmdType: CmdType
        var content: Data
        var rawData: Data
    }
    
    enum Style: UInt8 {
        case wifiSSID = 0, wifiPassword, wifiSecurity, common
    }
    
    enum CmdType: UInt8 {
        case sn = 1
        case resetToAP = 2
        case modifyAPPassword = 3
        case wifiMode = 4
        case configuerWifi = 5
        case firmwareVersion = 6
        case staIp = 7
    }
    
    //输入数据需要保证符合指令格式的
    static func resolve(data: Data) -> ResolveModel? {
        
        if data[0] != 0x7f {
            return nil
        }
        if let cmdType = CmdType.init(rawValue: data[3]) {
            let length = data.readValue(offset: 1, as: UInt16.self)!
            let content = Data(data[4...length+2])
            return ResolveModel.init(cmdType: cmdType, content: content, rawData: data)
        }else {
            return nil
        }
    }
    
    static func regularCmd(type: CmdType, content: Data?) -> Data {
        
        var data = Data()
        data.append(0x7f)
        //内容和一字节指令类型
        let length = UInt16((content?.count ?? 0) + 1)
        data.append(length, as: UInt16.self)
        data.append(type.rawValue)
        if let content = content {
            data.append(content)
        }
        return cmd(content: data, style: .common)
    }
    
    static func wifiConfigureCmd(ssid: Data, password: Data, security: Data) -> Data {
        
        var data = Data()
        data.append(cmd(content: security, style: .wifiSecurity))
        data.append(cmd(content: ssid, style: .wifiSSID))
        data.append(cmd(content: password, style: .wifiPassword))
        return data
    }
    
    private static func cmd(content: Data, style: Style) -> Data {
        
        var data = Data()
        data.append(contentsOf: [0, style.rawValue, UInt8(content.count)])
        data.append(content)
        return data
    }
}

class CP4000LikeBluetoothResolver: RYCommonResolver {
    
    class Model: RYCommonResolverModel {
        
        var type: CP4000LikeBluetoothCommand.CmdType = .sn
    }
    
    override func registerHandle() {
        
        let block = RYDataRouterBlock()
        block.minDataLength = 4
        block.handleBlock = {
            guard let cmdType = CP4000LikeBluetoothCommand.CmdType.init(rawValue: $0[3]) else { return nil }
            let cost = Int($0.readValue(offset: 1, as: UInt16.self)! + 3)
            let model = Model()
            model.cost = cost
            model.rawData = Data($0[0..<cost])
            model.type = cmdType
            model.data = Data($0[4..<cost])
            return model
        }
        self.router.registerHandle(Data.init([0x7f]), block: block)
    }
}
