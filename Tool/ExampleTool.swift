//
//  ExampleTool.swift
//  Tool
//
//  Created by ldc on 2020/10/22.
//

import UIKit

struct CmdSample {
    var title = ""
    var detailTitle = ""
    var closure: (() -> Void)?
}

protocol CmdSampleGenerator {
    
    var samples: [CmdSample] { set get }
}

fileprivate weak var AlertController: UIAlertController?

public extension UIViewController {
    
    func bk_presentAlertController(
        title: String?,
        message: String?,
        preferredStyle: UIAlertController.Style,
        actions: [UIAlertAction])
    -> Void
    {
        
        let closure = { () in
            let temp = UIAlertController.init(title: title, message: message, preferredStyle: preferredStyle)
            for action in actions {
                temp.addAction(action)
            }
            temp.popoverPresentationController?.sourceView = self.view
            temp.popoverPresentationController?.sourceRect = CGRect.init(x: 0, y: self.view.bounds.height/2, width: self.view.bounds.width, height: 1)
            self.present(temp, animated: true, completion: nil)
            AlertController = temp
        }
        if let alert = AlertController, let _ = alert.presentingViewController {
            
            alert.dismiss(animated: true, completion: closure)
        }else {
            closure()
        }
    }
    
    func bk_presentWarningAlertController(
        title: String,
        message: String,
        style: UIAlertAction.Style = .default,
        closure: ((UIAlertAction) -> Void)? = nil)
    -> Void
    {
        
        let action = UIAlertAction.init(title: "确定", style: style, handler: closure)
        bk_presentAlertController(title: title, message: message, preferredStyle: .alert, actions: [action])
    }
    
    func bk_presentDecisionAlertController(
        title: String?,
        message: String?,
        decisionTitle: String?,
        decisionClosure: @escaping (UIAlertAction) -> Void,
        cancelClosure: ((UIAlertAction) -> Void)? = nil)
    -> Void
    {
        
        let action1 = UIAlertAction.init(title: decisionTitle ?? "确定", style: .default, handler: decisionClosure)
        let action2 = UIAlertAction.init(title: "取消", style: .cancel, handler: cancelClosure)
        bk_presentAlertController(title: title, message: message, preferredStyle: .alert, actions: [action1, action2])
    }
}

extension UIViewController {
    
    func presentInputAlertController(msg: String, defaultText: String? = nil, inputDesc: String, closure: @escaping ((String) -> Void)) -> Void {
        
        let temp = UIAlertController(title: "提示", message: msg, preferredStyle: .alert)
        temp.addTextField {
            $0.placeholder = inputDesc
            $0.keyboardType = .numbersAndPunctuation
            $0.text = defaultText
        }
        let confirm = UIAlertAction(title: "确定", style: .default) { [weak temp] (_) in
            
            guard let textField = temp?.textFields?[0] else { return }
            guard let text = textField.text, !text.isEmpty else { return }
            closure(text)
        }
        let cancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        temp.addAction(confirm)
        temp.addAction(cancel)
        present(temp, animated: true, completion: nil)
    }
}

public extension Data {
    
    func removeZeroAtEnd() -> Data {
        
        if let index = self.firstIndex(of: 0) {
            if index == 0 {
                return Data()
            }else {
                return Data(self[0...index-1])
            }
        }
        return self
    }
    
    static func create<T>(_ value: T, as type: T.Type) -> Data {
        
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        pointer.pointee = value
        let data = Data.init(bytes: UnsafeRawPointer(pointer), count: MemoryLayout<T>.stride)
        pointer.deallocate()
        return data
    }
    
    mutating func append<T>(_ value: T, as type: T.Type) -> Void {
        
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        pointer.pointee = value
        let raw = pointer.withMemoryRebound(to: UInt8.self, capacity: 1) { $0 }
        append(raw, count: MemoryLayout<T>.stride)
        pointer.deallocate()
    }
    
    mutating func storeBytes<T>(_ value: T, toByteOffset offset: Int = 0, as type: T.Type) {
        
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        pointer.pointee = value
        let size = MemoryLayout<T>.stride
        replaceSubrange(offset..<offset + size, with: UnsafePointer(pointer), count: size)
        pointer.deallocate()
    }
    
    func readValue<T>(offset: Int = 0, as type: T.Type) -> T? {
        
        guard offset >= 0 else { return nil }
        let size = MemoryLayout<T>.stride
        if offset + size > count {
            return nil
        }
        let bytes = (self as NSData).bytes + offset
        let pointer = bytes.bindMemory(to: type, capacity: 1)
        return pointer.pointee
    }
}

extension Progress {
    
    var completedPercentage: Float {
        
        return Float(completedUnitCount)/Float(totalUnitCount)
    }
}
