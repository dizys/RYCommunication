//
//  BKDateExtension.swift
//  BaseKit
//
//  Created by ldc on 2018/5/29.
//  Copyright © 2018年 Xiamen Hanin. All rights reserved.
//

import Foundation

public enum Week {
    
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
    
    var index: Int {
        switch self {
        case .sunday:
            return 0
        case .monday:
            return 1
        case .tuesday:
            return 2
        case .wednesday:
            return 3
        case .thursday:
            return 4
        case .friday:
            return 5
        case .saturday:
            return 6
        }
    }
}

public extension Date {
    
    static func date(year: Int, month: Int, day: Int) -> Date {
        
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        return calendar.date(from: dateComponents)!
    }
    
    func plus(year: Int, month: Int, day: Int) -> Date {
        
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        return calendar.date(byAdding: dateComponents, to: self, wrappingComponents: false)!
    }
    ///日期对应月份天数
    var daysInMonth: Int {
        
        return Calendar.current.range(of: .day, in: .month, for: self)!.count
    }
    
    /// 1: 星期日 7:星期六
    var weekdayIndex: Week {
        
        let index = Calendar.current.component(.weekday, from: self)
        switch index {
        case 1:
            return .sunday
        case 2:
            return .monday
        case 3:
            return .tuesday
        case 4:
            return .wednesday
        case 5:
            return .thursday
        case 6:
            return .friday
        case 7:
            return .saturday
        default:
            fatalError()
        }
    }
    
    var year: Int {
        
        return Calendar.current.component(.year, from: self)
    }
    
    var month: Int {
        
        return Calendar.current.component(.month, from: self)
    }
    
    var day: Int {
        
        return Calendar.current.component(.day, from: self)
    }
    
    var hour: Int {
        
        return Calendar.current.component(.hour, from: self)
    }
    
    var minute: Int {
        
        return Calendar.current.component(.minute, from: self)
    }
    
    var second: Int {
        
        return Calendar.current.component(.second, from: self)
    }
    
    func formatString(_ format: String) -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
