//
//  Help.swift
//  Example
//
//  Created by ldc on 2020/9/10.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

import UIKit

struct ActionItem {
    var title: String
    var image: UIImage?
    var detailTitle: String?
    var action: (() -> Void)?
}
