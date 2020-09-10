//
//  CmdGenerator.swift
//  Example
//
//  Created by ldc on 2020/9/10.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

import Foundation
import RYCommunication

protocol CmdGenerator {
    
    var samples: [ActionItem] { set get }
    
    var accessory: RYAccessory { set get }
}
