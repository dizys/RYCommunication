//
//  DC24ACmdSampleGenerator.swift
//  Example
//
//  Created by ldc on 2020/10/22.
//

import Foundation
import UIKit
import SVProgressHUD
import Tool

class DC24ACmdSampleGenerator: CmdSampleGenerator {
    
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
        
        action = CmdSample.init(title: "硬件名称", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .getPrinterName, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "获取打印机信息", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .getPrinterInfo, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "序列号", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .getSn, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "模板", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .downModel, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "打印模板", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .printModel, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "固件版本", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .getFirmwareVersion, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "获取浓度", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .getDensity, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "获取浓度", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .setDensity, data: Data.init([1]))//浓度(0~2)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "状态", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .getStatus, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "RTC授时", closure: { [unowned self] in
            self.showTimeAlertViewController(title: "RTC授时", target: self.target!) { value in
                let data = value.data(using: String.Encoding.utf8)
                let cmd = DC24ALikeCommandGenerator.default().command(with: .updateTime, data: data)
                self.accessory.write(cmd, progress: nil)
            }
        })
        samples.append(action)
        
        action = CmdSample.init(title: "头片温度", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .headTemperature, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "头片温度", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .headTemperature, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        action = CmdSample.init(title: "抬起头片", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .controlHeadPressingDown, data: Data.init([0]))
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "下压头片", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .controlHeadPressingDown, data: Data.init([1]))
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "耗材余量", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .getCarbonBeltAllowance, data: Data.init([1]))
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "设置电位器档位", closure: { [unowned self] in
            let value = String(format: "%0X", 63)
            let cmd = DC24ALikeCommandGenerator.default().command(with: .setPotentiometerGearWhenPrinting, data: value.data(using: .utf8))//data：0x00~0x3F 第0-63档
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "获取电位器档位", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .getPotentiometerGearWhenPrinting, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "设置打印托架位置", closure: { [unowned self] in
            let value : UInt8 = 6 * 8
            let cmd = DC24ALikeCommandGenerator.default().command(with: .setPositionPrintHeadBracket, data: Data.init([value]))//设置打印头托架位置     | 范围 5mm~15mm, 距离mm*8后发送打印机，1字节
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "获取打印托架位置", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .getPositionPrintHeadBracket, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "设置打印位置", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .setPrintLocation, data: Data.init([104]))//设置打印位置           | 0dot ~ 104dot
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "获取打印位置", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .getPrintLocation, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "设置打印方向", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .setPrintDirection, data: Data.init([0]))// 正（0） 反（1）
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "获取打印方向", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .getPrintDirection, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "设置打印延时", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .setPrintDelay, data: Data.init([198]))
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "获取打印延时", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .getPrintDelay, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "头托架微动", closure: { [unowned self] in
            let value = "+\(0.5*8.0)"
            let cmd = DC24ALikeCommandGenerator.default().command(with: .setHeadBracketFrets, data: value.data(using: .utf8))
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "本批印刷数", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .batchPrintedNumber, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "总印刷数", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .batchPrintedTotalNumber, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "印刷速率", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .printSpeed, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "开启声音报警", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .buzzerDetection, data: Data.init([0]))// 蜂鸣器检测   (0开启检测 1关闭检测)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "关闭声音报警", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .buzzerDetection, data: Data.init([1]))// 蜂鸣器检测   (0开启检测 1关闭检测)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "开启LED指示灯显示", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .ledsDetection, data: Data.init([0]))
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "关闭LED指示灯显示", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .ledsDetection, data: Data.init([1]))
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
        
        action = CmdSample.init(title: "检测打印头托架", closure: { [unowned self] in
            let cmd = DC24ALikeCommandGenerator.default().command(with: .checkPrintHeadBracket, data: nil)
            self.accessory.write(cmd, progress: nil)
        })
        samples.append(action)
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
            self.dataAccessory?.auth = DC24AAuthorization()
            let resolver = DC24ADataResolver()
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
                #warning("待完善")
                print($0)
            }
        }
    }
    
    func configureResover() -> Void {
        
        self.accessory.resolver?.resolvedBlock = { [weak self] in
            guard let self = self, let temp = $0 as? DC24AResolverModel else { return }
            let data = temp.data
            var bytes = [UInt8](data)
            _ = UnsafeMutablePointer(&bytes)
            print(bytes)
            print("bytes")
            print(bytes.count)
            switch temp.commandType {
            case .getFirmwareVersion://固件版本
                let content = String.init(data: data, encoding: .utf8) ?? ""
                self.show("固件版本: \(content)")
            case .getPrinterName://打印机名称
                let content = String.init(data: data, encoding: .utf8) ?? ""
                self.show("打印机: \(content)")
            case .getSn:
                let content = String.init(data: data.removeZeroAtEnd(), encoding: .utf8) ?? ""
                self.show("序列号: \(content)")
            case .printerMileage:
                let content = String.init(data: data, encoding: .utf8) ?? ""
                self.show("打印里程: \(content)")
            case .getStatus:
                let status = DC24APrinterStatus.init(rawValue: UInt16(
                ))
                var content = ""
                if status.contains(.tandaiHuishouYichang){
                    content = content + "碳带回收异常"
                }
                if status.contains(.tandaiWeiJiaozhun) {
                    content = content + "，碳带未校准"
                }
                if status.contains(.gaowen) {
                    content = content + "，高温"
                }
                if status.contains(.dianyaGuodi) {
                    content = content + "，电压过低"
                }
                if status.contains(.dianyaGuogao) {
                    content = content + "，电压过高"
                }
                if status.contains(.feifaHaocai) {
                    content = content + "，非法耗材"
                }
                if status.contains(.huancunFeikong) {
                    content = content + "，缓存非空"
                }
                if status.contains(.haocaiYongjin) {
                    content = content + "，耗材用尽"
                }
                self.show("打印机状态*: \(content)")///\(content4)/\(content5)/\(content6)/\(content7)/\(content8)/")//data[4]为第一顺位状态，Bit0~Bit7 每一个位代表一个状态，状态不够时扩展data[5]，附表1：状态说明表 8碳带滚轴异常 | 7缓存非空 |    6耗材用尽 |     5非法耗材 | 4电压过高 | 3电压过低 |  2高温 |   1碳带未校准 | 0碳带回收异常
            case .downModel:
                let content = String.init(data: data, encoding: .utf8) ?? ""
                self.show("下载模板*: \(content)")
            case .updateTime:
                self.show("更新时间成功")
            case .getDensity:
                let content = data[0]
                self.show("浓度: \(content)")
            case .setDensity:
                self.show("设置浓度成功")
            case .autoResponse:
                let content = String.init(data: data, encoding: .utf8) ?? ""
                self.show("主动回传: \(content)")
            case .handshake:
                let content = String.init(data: data, encoding: .utf8) ?? ""
                self.show("握手校验: \(content)")
            case .headTemperature:
                let content = data[0]
                self.show("获取头片温度: \(content)")
            case .printModel:
                self.show("打印模板成功")
            case .controlHeadPressingDown:
                self.show("控制头片成功")
            case .getCarbonBeltAllowance:
                let content = data[0]
                self.show("碳带剩余: \(content)mm")
            case .getVersionCode:
                let content = String.init(data: data, encoding: .utf8) ?? ""
                self.show("版本号: \(content)")
            case .setPotentiometerGearWhenPrinting:
                self.show("设置打印时的电位器档位成功")
            case .getPotentiometerGearWhenPrinting:
                let content = data[0]
                self.show("获取打印时的电位器档位: \(content)")
            case .setPositionPrintHeadBracket:
                let content = String.init(data: data, encoding: .utf8) ?? ""
                self.show("设置打印头托架位置: \(content)")
            case .getPositionPrintHeadBracket:
                let content = data[0]
                self.show("获取打印头托架位置: \(content / 8)")
            case .setPrintLocation:
                let content = String.init(data: data, encoding: .utf8) ?? ""
                self.show("设置打印位置: \(content)")
            case .getPrintLocation:
                let content = data[0]
                self.show("获取打印位置: \(content)")
            case .setPrintDirection:
                let content = String.init(data: data, encoding: .utf8) ?? ""
                self.show("设置打印方向: \(content)")
            case .getPrintDirection:
                let content = data[0]
                self.show("获取打印方向: \(content == 0 ? "正面" : "反面")")
            case .setPrintDelay:
                self.show("设置打印延时成功")
            case .getPrintDelay:
                let content = data[0..<2]
                self.show("获取打印延时:\(content)")
            case .setHeadBracketFrets:
                let content = String.init(data: data, encoding: .utf8) ?? ""
                self.show("头托架微动: \(content)")
            case .batchPrintedNumber://本批印刷数 (开机从0开始累积 4字节)
                let content = data[0..<4]
                self.show("本批印刷数: \(content)")
            case .batchPrintedTotalNumber:// 总印刷数(4字节)
                let content = data[0..<4]
                self.show("总印刷数: \(content)")
            case .printSpeed://印刷速率 (张/分钟  1字节 )
                let content = data[0]
                self.show("印刷速率: \(content)张/分钟")
            case .buzzerDetection:
                self.show("设置蜂鸣器检测成功")
            case .ledsDetection:
                self.show("设置LED灯检测成功")
            case .checkPrintHeadBracket://检测打印头托架
                self.show("检测打印头托架成功")
            case .getPrinterInfo:
                
                let content1 = String.init(data: Data(data[0..<32]), encoding: .utf8) ?? ""//打印机名称
                let content2 = String.init(data: Data(data[32..<64]), encoding: .utf8) ?? ""//生产线编号
                let content3 = data[64]//托架位置
                let content4 = data[65]//打印位置
                let content5 = data[66]//碳带剩余长度
                let content6 = data[70]//本批打印
                let content7 = data[74]//总印数
                let content8 = data[78]//速率（包/分钟）
                let content9 = String.init(data: Data(data[79..<111]), encoding: .utf8) ?? "" //序列号
                let content10 = String.init(data: Data(data[111..<127]), encoding: .utf8) ?? ""
                let content11 = String.init(data: Data(data[127..<143]), encoding: .utf8) ?? ""
                let content12 = String.init(data: Data(data[143..<175]), encoding: .utf8) ?? ""
                let content13 = String.init(data: Data(data[175..<187]), encoding: .utf8) ?? ""
                
                let time = Data(data[127..<143]).readValue(as: UInt16.self)!
                self.show("打印机名称: \(content1)\n生产线编号: \(content2)\n托架位置: \(content3)dot\n打印位置: \(content4)dot\n碳带剩余长度: \(content5)\n本批打印: \(content6)\n总印数: \(content7)\n速率（包/分钟）: \(content8)\n序列号: \(content9)\n软件版本: \(content10)\n软件发布时间: \(content11)\n蓝牙名称: \(content12)\n蓝牙MAC地址: \(content13)")
            default:
                break
            }
            
        }
    }
    
    func show(_ msg: CustomStringConvertible) -> Void {
        
        self.target?.bk_presentWarningAlertController(title: "", message: msg.description)
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
    func showTimeAlertViewController(title : String, target: UIViewController,
                                 completeClosure: @escaping ((String) -> Void)) -> Void {
        
        let temp = UIAlertController.init(title: title, message: nil, preferredStyle: .alert)
        var action = UIAlertAction.init(title: "取消", style: .cancel, handler: nil)
        temp.addAction(action)
        action = UIAlertAction.init(title: "确定", style: .default, handler: { [weak temp] (_) in
            guard let temp = temp, let textFields = temp.textFields else { return }
            guard let ssid = textFields.first?.text else { return }
            completeClosure(ssid)
        })
        temp.addAction(action)
        temp.addTextField { [weak temp] in
            guard let _ = temp else { return }
            $0.placeholder = "请输入" + title
            $0.text = {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                return dateFormatter.string(from: Date())
            }()
        }
        target.present(temp, animated: true, completion: nil)
    }
//    func showTimeAlertViewController(title : String, target: UIViewController,
//                                 completeClosure: @escaping ((String) -> Void)) -> Void {
//
//        let temp = UIAlertController.init(title: title, message: nil, preferredStyle: .alert)
//        var action = UIAlertAction.init(title: "取消", style: .cancel, handler: nil)
//        temp.addAction(action)
//        action = UIAlertAction.init(title: "确定", style: .default, handler: { [weak temp] (_) in
//            guard let temp = temp, let textFields = temp.textFields else { return }
//            guard let ssid = textFields.first?.text else { return }
//            completeClosure(ssid)
//        })
//        temp.addAction(action)
//        temp.addTextField { [weak temp] in
//            guard let _ = temp else { return }
//            $0.placeholder = "请输入" + title
//            $0.text = {
//                let dateFormatter = DateFormatter()
//                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//                return dateFormatter.string(from: Date())
//            }()
//        }
//        target.present(temp, animated: true, completion: nil)
//    }

}
