//
//  HHDCBleConnectViewController.swift
//  Example
//
//  Created by ldc on 2020/11/12.
//

import UIKit
import SVProgressHUD

class HDCBleConnectViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    let manager = RYCentralManager.share()
    var printer: RYBleAccessory?
    var didConnectClosure: ((RYBleAccessory) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        title = "蓝牙搜索"
        initCentralManagerBloack()
        startScan()
    }
    
    func startScan() -> Void {
        
        let option = RYBleScanOption()
        option.printerFilter = { (peripheral, _, _) in
            guard let name = peripheral.name else { return false }
            return name.uppercased().contains("DC24A-DC2C")
        }
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
    
    deinit {
        manager.stopScan()
        manager.discoverBlock = nil
        manager.powerOffBlock = nil
    }
}

extension HDCBleConnectViewController: UITableViewDelegate, UITableViewDataSource {
    
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "iden") ?? UITableViewCell.init(style: .default, reuseIdentifier: "iden")
        let printers = manager.printers
        cell.textLabel?.text = printers[indexPath.row].peripheral.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        printer = manager.printers[indexPath.row]
        printer?.services = [FF00BleService()]
        printer?.auth = DC24AAuthorization()
        printer?.resolver = DC24ADataResolver()
        SVProgressHUD.show(withStatus: "连接中...")
        printer?.connect({ 
            SVProgressHUD.dismiss()
            self.didConnectClosure?(self.printer!)
        }) { (error) in
            self.printer?.closedBlock = nil
            self.printer = nil
            SVProgressHUD.dismiss()
            switch ((error as NSError).domain, (error as NSError).code) {
            case (RYBleConnectErrorDomain, RYBleConnectErrorCode.timeout.rawValue):
                self.bk_presentWarningAlertController(title: "提示", message: "打印机连接超时，请重试", style: .destructive)
            default:
                self.bk_presentWarningAlertController(title: "提示", message: "连接失败: \(error)", style: .destructive)
            }
        }
    }
}
