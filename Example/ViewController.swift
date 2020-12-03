//
//  ViewController.swift
//  Example
//
//  Created by ldc on 2020/10/22.
//

import UIKit
import SVProgressHUD

fileprivate var TempAccessory: RYAccessory?

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var disconnectItem: UIBarButtonItem!
    @IBOutlet weak var addItem: UIBarButtonItem!
    
    @IBAction func disconnectAction(_ sender: UIBarButtonItem) {
        
        accessory?.disconnect()
        accessory = nil
        samplesGenerator = nil
        tableView.reloadData()
        addItem.isEnabled = true
        disconnectItem.isEnabled = false
    }
    
    @IBAction func addAction(_ sender: UIBarButtonItem) {
        
        let action1 = UIAlertAction.init(title: "BLE", style: .default, handler: { _ in
            
            let temp = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ble") as! HBleConnectViewController
            temp.didConnectClosure = { [unowned self] in
                self.accessory = $0
                self.navigationController?.popViewController(animated: true)
            }
            self.show(temp, sender: nil)
        })
        let action2 = UIAlertAction.init(title: "IP", style: .default, handler: { _ in
            self.presentInputAlertController(msg: "输入ip", defaultText: "192.168.1.", inputDesc: "", closure: {
                SVProgressHUD.show(withStatus: "连接中...")
                TempAccessory = RYSocketAccessory.init($0, port: 9101)
                TempAccessory?.auth = FT800Authorization()
                TempAccessory?.resolver = FT800DataResolver()
                TempAccessory?.connect({
                    SVProgressHUD.dismiss()
                    self.accessory = TempAccessory
                    TempAccessory = nil
                }, fail: { (error) in
                    SVProgressHUD.dismiss()
                    TempAccessory = nil
                    let error = error as NSError
                    self.bk_presentWarningAlertController(title: "提示", message: "连接失败" + ": (\(error.domain)-\(error.code))")
                })
            })
        })
        let cancel = UIAlertAction.init(title: "取消", style: .cancel, handler: nil)
        self.bk_presentAlertController(
            title: nil, 
            message: "选择连接方式", 
            preferredStyle: .actionSheet, 
            actions: [action1, action2, cancel]
        )
    }
    
    var accessory: RYAccessory? {
        didSet {
            if let temp = accessory {
                samplesGenerator = FT800CmdSampleGenerator.init(accessory: temp, target: self)
                disconnectItem.isEnabled = true
                addItem.isEnabled = false
                temp.closedBlock = { [weak self] _ in
                    self?.accessory = nil
                    self?.tableView.reloadData()
                }
            }else {
                samplesGenerator = nil
                disconnectItem.isEnabled = false
                addItem.isEnabled = true
            }
            tableView.reloadData()
        }
    }
    var samplesGenerator: CmdSampleGenerator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        return UIView()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let generator = samplesGenerator else {
            return 0
        }
        return generator.samples.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let generator = samplesGenerator else {
            fatalError()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "iden") ?? UITableViewCell.init(style: .default, reuseIdentifier: "iden")
        cell.textLabel?.text = generator.samples[indexPath.row].title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        samplesGenerator?.samples[indexPath.row].closure?()
    }
}
