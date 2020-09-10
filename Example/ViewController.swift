//
//  ViewController.swift
//  Example
//
//  Created by ldc on 2020/9/9.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

import UIKit
import BaseKitSwift

class ViewController: UIViewController {

    @IBOutlet weak var disconnectItem: UIBarButtonItem!
    
    @IBOutlet weak var connectItem: UIBarButtonItem!
    
    @IBOutlet weak var tableView: UITableView!
    
    
    var samples: [ActionItem] {
        
        return cmdGenerator == nil ? [] : cmdGenerator!.samples
    }
    
    var cmdGenerator: CmdGenerator? {
        
        didSet {
            if let generator = cmdGenerator {
                generator.accessory.closedBlock = { [weak self] in
                    self?.cmdGenerator = nil
                }
                disconnectItem.isEnabled = true
                connectItem.isEnabled = false
            }else {
                disconnectItem.isEnabled = false
                connectItem.isEnabled = true
            }
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "指令列表"
        view.backgroundColor = UIColor.white
        disconnectItem.isEnabled = false
    }
    
    @IBAction func connectAction(_ sender: UIBarButtonItem) {
        
        typealias TempCmdGenerator = CP4000LBleCmdGenerator
        
        let action1 = UIAlertAction.init(title: "BLE", style: .default, handler: { _ in
            
            BKBluetoothAuthorization.share.request {
                let temp = BleConnectViewController()
                temp.didConnectClosure = { [unowned self] in
                    self.cmdGenerator = TempCmdGenerator.init(with: $0)
                    self.navigationController?.popViewController(animated: true)
                }
                self.show(temp, sender: nil)
            }
        })
        let cancelAction = UIAlertAction.init(title: "取消", style: .cancel, handler: nil)
        self.bk_presentAlertController(title: "请选择连接方式", message: nil, preferredStyle: .actionSheet, actions: [action1, cancelAction])
    }
    
    @IBAction func disconnectAction(_ sender: Any) {
        
        cmdGenerator?.accessory.disconnect()
        cmdGenerator = nil
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
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
        
        return samples.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: "iden")
        if cell == nil {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: "iden")
        }
        cell?.textLabel?.text = samples[indexPath.row].title
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        samples[indexPath.row].action?()
    }
}

