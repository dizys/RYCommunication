//
//  BKStringExtension.swift
//  BaseKit
//
//  Created by ldc on 2018/5/23.
//  Copyright © 2018年 Xiamen Hanin. All rights reserved.
//

import UIKit
import CommonCrypto

public enum AKError: Error {
    case hexStringToDataOverflowoutCharacter
    case irregularHexString
}

public extension String {
    
    /// 获取字符串绘制高度
    ///
    /// - Parameters:
    ///   - width: 绘制区域宽度
    ///   - font: 绘制字体
    /// - Returns: 绘制的高度
    func drawHeight(with width: CGFloat, font: UIFont) -> CGFloat {
        
        let size = CGSize.init(width: width, height: CGFloat.greatestFiniteMagnitude)
        let rect = (self as NSString).boundingRect(with: size, options: [.usesFontLeading,.usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font : font], context: nil)
        return ceil(rect.height) + 1
    }
    
    /// 获取字符串单行绘制宽度
    ///
    /// - Parameter font: 字体
    /// - Returns: 返回宽度
    func drawWidth(with font: UIFont) -> CGFloat {
        
        let size = CGSize.init(width: CGFloat.greatestFiniteMagnitude, height: font.lineHeight)
        let rect = (self as NSString).boundingRect(with: size, options: [.usesFontLeading,.usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font : font], context: nil)
        return ceil(rect.width) + 1
    }
}

public extension String {
    
    /// 将十六进制字符串转为数据流,必须为 12 34 ef ab 这种格式，每组为两个十六进制字符，中间用空格隔开
    ///
    /// - Returns: 数据流
    /// - Throws: 字符串存在非十六进制字符错误
    func hexStringToData() throws -> Data {
        
        if !isRegularHexString {
            throw AKError.irregularHexString
        }
        var data = Data()
        var temp = self.replacingOccurrences(of: "/n", with: "")
        temp = temp.replacingOccurrences(of: "/r", with: "")
        temp = temp.replacingOccurrences(of: " ", with: "")
        for i in 0..<temp.count/2 {
            let sub = (temp as NSString).substring(with: NSRange.init(location: 2*i, length: 2))
            if let result = UInt8(sub,radix: 16) {
                data.append(result)
            }else {
                throw AKError.hexStringToDataOverflowoutCharacter
            }
        }
        return data
    }
}

public extension String {
    
    private static var invertedEmailCharacterSet: CharacterSet = {
        let letters = "abcdefghijklmnopqrstuvwxyz"
        return CharacterSet.init(charactersIn: letters + letters.uppercased() + "0123456789.@-_").inverted
    }()
    
    //是否是规则的十六进制字符串，"12 54 ef"格式
    var isRegularHexString: Bool {
        
        let regularString = "^[ \\n\\r]*([0-9a-fA-F]{2}[ \\n\\r]+)*([0-9a-fA-F]{2})*$"
        let predicate = NSPredicate.init(format: "SELF MATCHES %@", regularString)
        return predicate.evaluate(with: self)
    }
    
    var isPhoneNo: Bool {
        
        let pattern = "^((1[389][0-9])|(14[579])|(15[0-3,5-9])|(16[2567])|(17[0-8]))\\d{8}$"
        let predicate = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: self)
    }
    
    var isIp: Bool {
        let numPre = "(2[0-4]\\d|25[0-5]|[01]?\\d\\d?)"
        let rex = String.init(format: "^(%@.){3}%@$", numPre, numPre)
        let predicate = NSPredicate.init(format: "SELF MATCHES %@", rex)
        return predicate.evaluate(with: self)
    }
    
    var isEmail: Bool {
        
        #if true
        if let _ = self.rangeOfCharacter(from: String.invertedEmailCharacterSet) {
            return false
        }
        let components = self.components(separatedBy: "@")
        if components.count != 2 {
            return false
        }
        let name = components[0]
        if name.components(separatedBy: ".").contains(where: { $0.isEmpty }) {
            return false
        }
        let domain = components[1]
        let items = domain.components(separatedBy: ".")
        if items.count <= 1 || items.contains(where: { $0.isEmpty }) {
            return false
        }
        return true
        #else
        //MARK: 字符串太长时使用正则匹配效率过低，弃用
        let char = "[a-zA-Z0-9-_]"
        let rex = "^\(char)+(.\(char)+)+@\(char)+(.\(char)+)+$"
        let predicate = NSPredicate.init(format: "SELF MATCHES %@", rex)
        return predicate.evaluate(with: self)
        #endif
    }
}

public extension String {
    
    var md5: String {
        
        return self.data(using: .utf8)!.md5
    }
    
    var sha1: String {
        
        return self.data(using: .utf8)!.sha1
    }
}

public extension String {
    
    subscript(i: ClosedRange<Int>) -> Substring {
        
        let start = self.index(self.startIndex, offsetBy: i.lowerBound)
        let end = self.index(self.startIndex, offsetBy: i.upperBound)
        return self[start...end]
    }
}

public enum Language: Int {
    
    case none = 0, en, zh_Hans, ja
}

public extension String {
    
    static var lang = Language.none
    
    var localized: String {
        
        var result: String
        switch String.lang {
        case .none:
            result = Bundle.main.localizedString(forKey: self, value: nil, table: nil)
        case .zh_Hans:
            result = Bundle.main.localizedString(forKey: self, value: nil, table: "zh-Hans.lproj/Localizable")
        case .ja:
            result = Bundle.main.localizedString(forKey: self, value: nil, table: "ja.lproj/Localizable")
        case .en:
            result = Bundle.main.localizedString(forKey: self, value: nil, table: "en.lproj/Localizable")
        }
        if result.isEmpty {
            return self
        }
        return result
    }
    
    static let languageChanged = Notification.Name("string.language.did.change")
}

public extension String {
    
    var trim: String {
        
        return trimmingCharacters(in: CharacterSet.whitespaces)
    }
}

var FrameworkBundle: Bundle = {
    
    return Bundle.init(for: BKKeyboardAutoAdjust.self)
}()

extension String {
    
    var bk_localized: String {
        
        switch String.lang {
        case .none:
            return FrameworkBundle.localizedString(forKey: self, value: nil, table: nil)
        case .zh_Hans:
            return FrameworkBundle.localizedString(forKey: self, value: nil, table: "zh-Hans.lproj/Localizable")
        case .ja:
            return FrameworkBundle.localizedString(forKey: self, value: nil, table: "ja.lproj/Localizable")
        case .en:
            return FrameworkBundle.localizedString(forKey: self, value: nil, table: "en.lproj/Localizable")
        }
    }
}

public extension String {
    
    enum VersionComponentMax {
        case UInt8
        case UInt16
    }
    
    func versionable(component count: Int) -> String {
        
        let mstr = NSMutableString.init(string: self)
        let re = try! NSRegularExpression.init(pattern: "[^0-9.]+", options: [])
        let range = NSRange.init(location: 0, length: mstr.length)
        re.replaceMatches(in: mstr, options: [], range: range, withTemplate: ".")
        var items = mstr.components(separatedBy: ".").filter({ !$0.isEmpty })
        while items.count > count {
            items.removeLast()
        }
        while items.count < count {
            items.append("0")
        }
        return items.joined(separator: ".")
    }
    
    func versionRepr(component max: VersionComponentMax = .UInt16) -> UInt64 {
        
        switch max {
        case .UInt8:
            let items = versionable(component: 8).components(separatedBy: ".")
            var temp = items.map({ UInt8($0) ?? UInt8.max })
            temp.reverse()
            return Data.init(temp).readValue(as: UInt64.self)!
        case .UInt16:
            let items = versionable(component: 4).components(separatedBy: ".")
            let temp = items.map({ (UInt16($0) ?? UInt16.max).bigEndian })
            var data = Data()
            for item in temp {
                data.append(item, as: UInt16.self)
            }
            return data.readValue(as: UInt64.self)!.bigEndian
        }
    }
}
