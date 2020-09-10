//
//  BleConnectViewController.swift
//  Example
//
//  Created by ldc on 2020/9/10.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

import UIKit
import RYCommunication
import BaseKitSwift
import SVProgressHUD

class BleConnectViewController: UIViewController {
    
    let manager = RYCentralManager.share()
    var printer: RYBleAccessory?
    var didConnectClosure: ((RYBleAccessory) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        title = "蓝牙连接".localized
        initCentralManagerBloack()
        startScan()
        makeConstraint()
    }
    
    func startScan() -> Void {
        
        let option = RYBleScanOption()
        option.serviceUUIDs = [CBUUID.init(string: "1B7E8251-2877-41C3-B46E-CF057C562023")]
        manager.startScan(option)
    }
    
    func initCentralManagerBloack() -> Void {
        
        manager.discoverBlock = { [weak self] _ in
            
            guard let count = self?.manager.printers.count else { return }
            self?.tableView.insertRows(at: [IndexPath.init(row: count - 1, section: 0)], with: .automatic)
        }
        manager.powerOffBlock = { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    func makeConstraint() -> Void {
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(self.snp.top)
            $0.bottom.left.right.equalToSuperview()
        }
    }
    
    lazy var tableView: UITableView = {
        
        let temp = UITableView.init(frame: .zero, style: UITableView.Style.grouped)
        temp.delegate = self
        temp.dataSource = self
        temp.estimatedRowHeight = 44
        temp.estimatedSectionHeaderHeight = 0
        temp.estimatedSectionFooterHeight = 0
        temp.separatorInset = .zero
        self.view.addSubview(temp)
        return temp
    }()
    
    deinit {
        manager.stopScan()
        manager.discoverBlock = nil
        manager.powerOffBlock = nil
    }
}

extension BleConnectViewController {
    
    @objc func refreshAction() {
        
        manager.stopScan()
        self.tableView.reloadData()
        startScan()
    }
}

extension BleConnectViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        return nil
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return manager.printers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let iden = "iden"
        var cell = tableView.dequeueReusableCell(withIdentifier: iden)
        if cell == nil {
            cell = UITableViewCell.init(style: .value1, reuseIdentifier: iden)
        }
        let printers = manager.printers
        cell?.textLabel?.text = printers[indexPath.row].peripheral.name
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        printer = manager.printers[indexPath.row]
        SVProgressHUD.show(withStatus: "连接中...".localized)
        printer?.connect({ 
            SVProgressHUD.dismiss()
            self.didConnectClosure?(self.printer!)
        }) { (error) in
            self.printer?.closedBlock = nil
            self.printer = nil
            SVProgressHUD.dismiss()
            switch ((error as NSError).domain, (error as NSError).code) {
            case (RYBleConnectErrorDomain, RYBleConnectErrorCode.timeout.rawValue):
                self.bk_presentWarningAlertController(title: "提示".localized, message: "打印机连接超时，请重试".localized, style: .destructive)
            default:
                self.bk_presentWarningAlertController(title: "提示", message: "连接失败: \(error)", style: .destructive)
            }
        }
    }
}
