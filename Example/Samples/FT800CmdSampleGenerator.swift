//
//  FT800CmdSampleGenerator.swift
//  Example
//
//  Created by ldc on 2020/10/22.
//

import Foundation
import UIKit
import SVProgressHUD
import Tool

extension FT800PackageType: CustomStringConvertible {
    
    public var description: String {
        
        switch self {
        case .handshake:
            return "握手包"
        case .command:
            return "命令包"
        case .data:
            return "数据包"
        case .autoResponse:
            return "自动回传包"
        case .repeater:
            return "数据转发包"
        default:
            return "未知包"
        }
    }
}

extension FT800ResolverModel {
    
    open override var description: String {
        
        return "*****\n协议版本: \(protocolVersion)\n包序号: \(packageId)\n包类型: \(type)\n控制位: \(control)\n应用端口: \(app_port)\n"
    }
}

extension FT800PrinterStatus1: CustomStringConvertible {
    
    var desc_items: [String] {
        
        var items = [String]()
        if contains(.highTemperature) {
            items.append("高温")
        }
        if contains(.powerTooLow) {
            items.append("低电量")
        }
        if contains(.coverOpen) {
            items.append("开盖")
        }
        if contains(.paperNotTakeOut) {
            items.append("未取纸")
        }
        if contains(.paperAbsent) {
            items.append("缺纸")
        }
        if contains(.cutterError) {
            items.append("切刀错误")
        }
        if contains(.locationError) {
            items.append("定位失败")
        }
        if contains(.offline) {
            items.append("脱机")
        }
        return items
    }
    
    public var description: String {
        
        return desc_items.joined(separator: "|")
    }
}

extension FT800PrinterStatus2: CustomStringConvertible {
    
    static let all: FT800PrinterStatus2 = [
        .bufferIsNotEmpty,
        .illegalRibbon,
        .ribbonExhausted,
        .paused,
    ]
    
    var desc_items: [String] {
        
        var items = [String]()
        if contains(.bufferIsNotEmpty) {
            items.append("缓存非空")
        }
        if contains(.illegalRibbon) {
            items.append("非法耗材")
        }
        if contains(.ribbonExhausted) {
            items.append("耗材用尽")
        }
        if contains(.paused) {
            items.append("暂停")
        }
        return items
    }
    
    public var description: String {
        
        return desc_items.joined(separator: "|")
    }
}

extension FT800PrinterStatus3: CustomStringConvertible {
    
    var desc_items: [String] {
        
        var items = [String]()
        if contains(.idle) {
            items.append("空闲")
        }else {
            items.append("正忙")
        }
        return items
    }
    
    public var description: String {
        
        return desc_items.joined(separator: "|")
    }
}

extension FT800PackageResult: CustomStringConvertible {
    
    public var description: String {
        
        switch self {
        case .ok:
            return "正常"
        case .fail:
            return "执行失败"
        case .crcError:
            return "crc 检验失败"
        case .formatError:
            return "格式错误"
        case .busy:
            return "打印机正忙"
        default:
            fatalError()
        }
    }
}

class FT800CmdSampleGenerator: CmdSampleGenerator {
    
    var samples: [CmdSample]
    
    let accessory: RYAccessory
    weak var target: UIViewController?
    
    var dataAccessory: RYAccessory?
    let bitmap = try! Data.init(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: "bitmap", ofType: "bin")!))
    var timer: Timer?
    
    init(accessory: RYAccessory, target: UIViewController) {
        self.accessory = accessory
        self.target = target
        self.samples = []
        initSamples()
        configureResover()
    }
    
    func initSamples() -> Void {
        
        var action: CmdSample
        
        action = CmdSample.init(title: "固件版本", closure: { [unowned self] in
            let cmd = FT800LikeCommandGenerator.default().command(with: .getFirmwareVersion, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "电量", closure: { [unowned self] in
            let cmd = FT800LikeCommandGenerator.default().command(with: .getPower, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "状态", closure: { [unowned self] in
            let cmd = FT800LikeCommandGenerator.default().command(with: .getStatus, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "型号", closure: { [unowned self] in
            let cmd = FT800LikeCommandGenerator.default().command(with: .getPrinterModel, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "蓝牙名称", closure: { [unowned self] in
            let cmd = FT800LikeCommandGenerator.default().command(with: .getBtName, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        if accessory is RYBleAccessory {
            
            action = CmdSample.init(title: "Wi-Fi模式", closure: { [unowned self] in
                let cmd = FT800LikeCommandGenerator.default().command(with: .getWiFiMode, data: nil)
                self.accessory.write(cmd, progress: nil)
            })
            samples.append(action)
            
            action = CmdSample.init(title: "STA信息", closure: { [unowned self] in
                let cmd = FT800LikeCommandGenerator.default().command(with: .getStaInfo, data: nil)
                self.accessory.write(cmd, progress: nil)
            })
            samples.append(action)
            
            action = CmdSample.init(title: "STA配网测试", closure: { [unowned self] in
                guard let target = self.target else { return }
                showAlertViewController(target: target, completeClosure: {
                    let ssid = $0.data(using: .utf8)!
                    let psd = ($1 ?? "").data(using: .ascii)!
                    let cmd = FT800LikeCommandGenerator.default().configureStaWiFi(ssid, password: psd, security: .wpa_wpa2_psk)
                    self.accessory.write(cmd, progress: nil)
                })
            })
            samples.append(action)
            
            action = CmdSample.init(title: "关闭Wi-Fi", closure: { [unowned self] in
                let cmd = FT800LikeCommandGenerator.default().command(with: .setWiFiMode, data: Data.init([0]))
                self.accessory.write(cmd, progress: nil)
            })
            samples.append(action)
            
            action = CmdSample.init(title: "设置AP模式", closure: { [unowned self] in
                let cmd = FT800LikeCommandGenerator.default().command(with: .setWiFiMode, data: Data.init([1]))
                self.accessory.write(cmd, progress: nil)
            })
            samples.append(action)
            
            action = CmdSample.init(title: "设置STA模式", closure: { [unowned self] in
                let cmd = FT800LikeCommandGenerator.default().command(with: .setWiFiMode, data: Data.init([2]))
                self.accessory.write(cmd, progress: nil)
            })
            samples.append(action)
        }
        
        action = CmdSample.init(title: "获取序列号", closure: { [unowned self] in
            let cmd = FT800LikeCommandGenerator.default().command(with: .getSn, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "获取制造商名称", closure: { [unowned self] in
            let cmd = FT800LikeCommandGenerator.default().command(with: .getManuName, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "获取打印机名称", closure: { [unowned self] in
            let cmd = FT800LikeCommandGenerator.default().command(with: .getPrinterName, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "获取自动关机时间", closure: { [unowned self] in
            let cmd = FT800LikeCommandGenerator.default().command(with: .getShutdownTime, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "获取浓度", closure: { [unowned self] in
            let cmd = FT800LikeCommandGenerator.default().command(with: .getDensity, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "设置自动关机时间", closure: { [unowned self] in
            self.target?.presentInputAlertController(msg: "设置自动关机时间，单位秒", inputDesc: "0~\(UInt32.max)", closure: {
                if let temp = UInt32.init($0) {
                    let content = Data.create(temp, as: UInt32.self)
                    var cmd = FT800LikeCommandGenerator.default().command(with: .setShutdownTime, data: content)
                    cmd.append(FT800LikeCommandGenerator.default().command(with: .doSaveConfig, data: nil))
                    self.accessory.write(cmd, progress: nil)
                }
            })
        })
        samples.append(action)
        
        action = CmdSample.init(title: "设置浓度", closure: { [unowned self] in
            self.target?.presentInputAlertController(msg: "设置浓度", inputDesc: "0~3", closure: {
                if let temp = UInt8.init($0) {
                    let content = Data.create(temp, as: UInt8.self)
                    var cmd = FT800LikeCommandGenerator.default().command(with: .setDensity, data: content)
                    cmd.append(FT800LikeCommandGenerator.default().command(with: .doSaveConfig, data: nil))
                    self.accessory.write(cmd, progress: nil)
                }
            })
        })
        samples.append(action)
        
        if accessory is RYSocketAccessory {
            
            action = CmdSample.init(title: "取消任务", closure: { [unowned self] in
                let cmd = FT800LikeCommandGenerator.default().command(with: .cancelPrint, data: nil)
                self.accessory.write(cmd, progress: nil)
            })
            samples.append(action)
            
            action = CmdSample.init(title: "图片打印", closure: { [unowned self] in
                SVProgressHUD.show(withStatus: "发送图片打印命令")
                self.validateDataConnect {
                    let cmd = FT800LikeCommandGenerator.default().imagePrintCmd(self.bitmap, height: 3488, options: [.cut], copies: 1, taskIndex: 1, taskCount: 1, taskId: 1)
                    self.dataAccessory?.write(cmd, progress: nil)
                    self.timer = Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(self.sendImagePrintCmdTimeout), userInfo: nil, repeats: false)
                }
            })
            samples.append(action)
        }
    }
    
    @objc func sendImagePrintCmdTimeout() {
        
        SVProgressHUD.showError(withStatus: "打印机应答图片打印命令超时")
        self.dataAccessory?.disconnect()
    }
    
    @objc func sendDataTimeout() {
        SVProgressHUD.showError(withStatus: "打印机应答打印数据超时")
        self.dataAccessory?.disconnect()
    }
    
    func validateDataConnect(to closure: @escaping () -> Void) -> Void {
        
        if self.dataAccessory != nil {
            closure()
        }else {
            guard let temp = accessory as? RYSocketAccessory else { return }
            self.dataAccessory = RYSocketAccessory.init(temp.ip, port: 9100)
            self.dataAccessory?.auth = FT800Authorization()
            let resolver = FT800DataResolver()
            self.dataAccessory?.resolver = resolver
            self.dataAccessory?.connect({ 
                closure()
            }, fail: {
                SVProgressHUD.showError(withStatus: $0.localizedDescription)
                self.dataAccessory = nil
            })
            self.dataAccessory?.closedBlock = { [weak self] _ in
                self?.dataAccessory = nil
                self?.timer?.invalidate()
                self?.timer = nil
                SVProgressHUD.showError(withStatus: "数据通道连接断开")
            }
            self.dataAccessory?.resolver?.resolvedBlock = { [weak self] in
                guard let self = self else { return }
                switch $0 {
                case let temp as FT800ResolverModel:
                    switch temp.type {
                    case .data:
                        self.timer?.invalidate()
                        self.timer = nil
                        let content = temp.data
                        let result = FT800PackageResult.init(rawValue: content[1])
                        switch result {
                        case .ok:
                            SVProgressHUD.showSuccess(withStatus: "数据发送成功")
                        default:
                            SVProgressHUD.showError(withStatus: "数据发送失败")
                        }
                        self.dataAccessory?.disconnect()
                        self.dataAccessory = nil
                    case .command:
                        if let model = FT800CommandResolveModel.init(temp) {
                            switch model.type {
                            case .blackAndWhitePrint:
                                self.timer?.invalidate()
                                self.timer = nil
                                guard model.result == .ok else {
                                    SVProgressHUD.dismiss()
                                    self.show("\(temp)\n\(model.result)")
                                    self.dataAccessory?.disconnect()
                                    self.dataAccessory = nil
                                    return
                                }
                                self.validateDataConnect {
                                    //taskId 需要同打印指令一致
                                    let data = FT800LikeCommandGenerator.default().imagePrint(self.bitmap, taskId: 1)
                                    self.dataAccessory?.write(data, progress: {
                                        SVProgressHUD.showProgress($0.completedPercentage)
                                        if $0.completedPercentage == 1 {
                                            self.timer = Timer.scheduledTimer(timeInterval: 40, target: self, selector: #selector(self.sendDataTimeout), userInfo: nil, repeats: false)
                                        }
                                    })
                                }
                            default:
                                break
                            }
                        }
                    default:
                        break
                    }
                default:
                    break
                }
            }
        }
    }
    
    func configureResover() -> Void {
        
        self.accessory.resolver?.resolvedBlock = { [weak self] in
            
            guard let self = self else { return }
            switch $0 {
            case let temp as FT800ResolverModel:
                switch temp.type {
                case .autoResponse:
                    let data = temp.data
                    if let type = FT800AutoResponseType.init(rawValue: data[0]) {
                        switch type {
                        case .shutdown:
                            self.show("打印机关机")
                        case .taskCompleted:
                            self.show("打印完成")
                        case .printerStatus:
                            let status1 = FT800PrinterStatus1.init(rawValue: data[1])
                            let status2 = FT800PrinterStatus2.init(rawValue: data[2])
                            let status3 = FT800PrinterStatus3.init(rawValue: data[3])
                            print("打印机状态:\n状态1: \(status1)\n状态2: \(status2)\n状态3: \(status3)")
                        default:
                            break
                        }
                    }
                case .command: 
                    if let model = FT800CommandResolveModel.init(temp) {
                        guard model.result == .ok else {
                            self.show("\(temp)\n\(model.result)")
                            return
                        }
                        let data = model.content
                        switch model.type {
                        case .getFirmwareVersion:
                            let version = String.init(data: data, encoding: .utf8) ?? ""
                            self.show("固件版本: \(version)")
                        case .getPower:
                            let power = data[0]
                            self.show("\(temp)\n电量: \(power)")
                        case .getStatus:
                            let status1 = FT800PrinterStatus1.init(rawValue: data[0])
                            let status2 = FT800PrinterStatus2.init(rawValue: data[1])
                            let status3 = FT800PrinterStatus3.init(rawValue: data[2])
                            self.show("打印机状态:\n状态1: \(status1)\n状态2: \(status2)\n状态3: \(status3)")
                        case .getWiFiMode:
                            let mode = data[0]
                            self.show("\(temp)\nWi-Fi模式: \(mode == 0 ? "关闭" : mode == 1 ? "AP" : "STA")")
                        case .getStaInfo:
                            let ssid = String.init(data: Data(data[0..<32]).removeZeroAtEnd(), encoding: .utf8) ?? ""
                            let ip = data[32..<36].map({ String.init(format: "%i", $0) }).joined(separator: ".")
                            self.show("\(temp)\nssid: \(ssid)\nip: \(ip)状态: \(ip == "0.0.0.0" ? "连接中" : "已连接")")
                        case .getPrinterModel:
                            let model = String.init(data: data.removeZeroAtEnd(), encoding: .utf8) ?? ""
                            self.show("\(temp)\n机型: \(model)")
                        case .getBtName:
                            let name = String.init(data: data.removeZeroAtEnd(), encoding: .utf8) ?? ""
                            self.show("\(temp)\n蓝牙名称: \(name)")
                        case .getWifiVersion:
                            self.show("\(temp)\nWi-Fi固件版本: \(data.map({ String.init(format: "%02x", $0) }).joined(separator: " "))")
                        case .setWiFiMode:
                            self.show("设置Wi-Fi模式执行成功")
                        case .getSn:
                            let sn = String.init(data: data.removeZeroAtEnd(), encoding: .utf8) ?? ""
                            self.show("序列号: \(sn)")
                        case .getManuName:
                            let manuName = String.init(data: data.removeZeroAtEnd(), encoding: .utf8) ?? ""
                            self.show("厂商名称: \(manuName)")
                        case .getPrinterName:
                            let printerName = String.init(data: data.removeZeroAtEnd(), encoding: .utf8) ?? ""
                            self.show("打印机名称: \(printerName)")
                        case .getDensity:
                            let density = data[0]
                            self.show("浓度: \(density)")
                        case .getShutdownTime:
                            let time = data.readValue(as: UInt32.self)!
                            self.show("自动关机时间: \(time)s")
                        case .setDensity:
                            self.show("浓度设置执行成功")
                        case .setShutdownTime:
                            self.show("自动关机时间设置执行成功")
                        case .doSaveConfig:
                            self.show("设置信息保存成功")
                        case .configureStaWiFi:
                            self.show("配网执行成功")
                        default:
                            break
                        }
                    }
                default:
                    break
                }
            default:
                break
            }
        }
    }
    
    func show(_ msg: CustomStringConvertible) -> Void {
        
        self.target?.bk_presentWarningAlertController(title: "", message: msg.description)
    }
}

func showAlertViewController(target: UIViewController, 
                             completeClosure: @escaping ((String, String?) -> Void)) -> Void {
    
    let temp = UIAlertController.init(title: "配网", message: nil, preferredStyle: .alert)
    var action = UIAlertAction.init(title: "取消", style: .cancel, handler: nil)
    temp.addAction(action)
    action = UIAlertAction.init(title: "确定", style: .default, handler: { [weak temp] (_) in
        guard let temp = temp, let textFields = temp.textFields, textFields.count > 1 else { return }
        guard let ssid = textFields[0].text else { return }
        let password = textFields[1].text
        completeClosure(ssid, password)
    })
    action.isEnabled = false
    temp.addAction(action)
    temp.addTextField { [weak temp] in
        guard let temp = temp else { return }
        $0.placeholder = "请输入Wi-Fi名称"
        NotificationCenter.default.addObserver(temp, selector: #selector(UIAlertController.textFieldTextDidChange), name: UITextField.textDidChangeNotification, object: $0)
    }
    temp.addTextField { [weak temp] in
        guard let temp = temp else { return }
        $0.placeholder = "请输入Wi-Fi密码"
        $0.keyboardType = .URL
        NotificationCenter.default.addObserver(temp, selector: #selector(UIAlertController.textFieldTextDidChange), name: UITextField.textDidChangeNotification, object: $0)
    }
    temp.textFieldTextDidChangeClosure = {
        guard let textFields = $0, textFields.count > 1 else { return }
        guard let ssid = textFields[0].text else { return }
        if ssid.isEmpty {
            $1[1].isEnabled = false
        }else {
            $1[1].isEnabled = true
        }
    }
    target.present(temp, animated: true, completion: nil)
}

extension UIAlertController {
    
    struct Key {
        static var textDidChangeClosure = 0
    }
    
    @objc func textFieldTextDidChange() {
        
        textFieldTextDidChangeClosure?(textFields, actions)
    }
    
    var textFieldTextDidChangeClosure: (([UITextField]?, [UIAlertAction]) -> Void)? {
        
        set {
            objc_setAssociatedObject(self, &Key.textDidChangeClosure, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
        
        get {
            return objc_getAssociatedObject(self, &Key.textDidChangeClosure) as? ([UITextField]?, [UIAlertAction]) -> Void
        }
    }
}
