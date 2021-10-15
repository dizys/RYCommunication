//
//  BKImageTitleButton.swift
//  BaseKitSwift
//
//  Created by ldc on 2019/12/13.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

import UIKit

public class BKImageTitleButton: UIControl {
    
    public enum LayoutDirection {
        case horizonal
        case vertical
    }
    
    public enum ComponentType {
        case image
        case title
    }
    
    public enum LayoutOption {
        case center(CGFloat)
        case leading(CGFloat)
        case trailing(CGFloat)
        case leadingTrailing(CGFloat, CGFloat)
    }
    
    public override var isHighlighted: Bool {
        
        set {
            alpha = highlightEnabled ? newValue ? 0.5 : 1 : 1
            super.isHighlighted = newValue
        }
        
        get { super.isHighlighted }
    }
    
    public var highlightEnabled = true
    
    let layoutDirection: LayoutDirection
    let leadingComponentType: ComponentType
    let layoutOption: LayoutOption
    
    let alignSpace: CGFloat
    
    public override var isSelected: Bool {
        
        didSet {
            if oldValue != isSelected {
                updateImageViewConstraint()
            }
        }
    }
    
    public var image: UIImage? {
        
        didSet {
            if !isSelected {
                updateImageViewConstraint()
            }
        }
    }
    
    public var selectedImage: UIImage? {
        
        didSet {
            if isSelected {
                updateImageViewConstraint()
            }
        }
    }
    
    func updateImageViewConstraint() -> Void {
        
        let image = isSelected ? self.selectedImage : self.image
        imageView.snp.updateConstraints {
            switch self.layoutDirection {
            case .horizonal:
                $0.width.equalTo(image == nil ? 0 : image!.size.width)
            case .vertical:
                $0.height.equalTo(image == nil ? 0 : image!.size.height)
            }
        }
        imageView.image = image
    }
    
    public init(
        layoutDirection: LayoutDirection, 
        leadingComponentType: ComponentType, 
        layoutOption: LayoutOption, 
        frame: CGRect = .zero,
        alignSpace: CGFloat = 2
    ) {
        self.layoutDirection = layoutDirection
        self.leadingComponentType = leadingComponentType
        self.layoutOption = layoutOption
        self.alignSpace = alignSpace
        super.init(frame: frame)
        makeConstraint()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func makeConstraint() -> Void {
        
        var leadingView: UIView
        var trailingView: UIView
        var titleLeading = true
        switch leadingComponentType {
        case .image:
            leadingView = imageView
            trailingView = titleLabel
            titleLeading = false
        case .title:
            leadingView = titleLabel
            trailingView = imageView
        }
        switch self.layoutDirection {
        case .horizonal:
            horizonalConstraint(leadingView: leadingView, trailingView: trailingView, titleLeading: titleLeading)
            break
        case .vertical:
            verticalConstraint(leadingView: leadingView, trailingView: trailingView, titleLeading: titleLeading)
        }
    }
    
    func horizonalConstraint(leadingView: UIView, trailingView: UIView, titleLeading: Bool) -> Void {
        
        layoutView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            switch self.layoutOption {
            case .center(_):
                $0.centerX.equalToSuperview()
                $0.width.lessThanOrEqualToSuperview()
            case .leading(let leading):
                $0.left.equalToSuperview().offset(leading)
                $0.right.equalToSuperview()
            case .trailing(let trailing):
                $0.left.equalToSuperview()
                $0.right.equalToSuperview().offset(-trailing)
            case .leadingTrailing(let leading, let trailing):
                $0.left.equalToSuperview().offset(leading)
                $0.right.equalToSuperview().offset(-trailing)
            }
        }
        leadingView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.height.lessThanOrEqualToSuperview()
            if !titleLeading {
                $0.width.equalTo(0)
            }
            switch self.layoutOption {
            case .center(_):
                $0.left.equalToSuperview()
            case .leading(_),
                 .leadingTrailing(_, _):
                $0.left.equalToSuperview()
            case .trailing(_):
                $0.left.greaterThanOrEqualToSuperview()
            }
        }
        trailingView.snp.updateConstraints {
            $0.centerY.equalToSuperview()
            $0.height.lessThanOrEqualToSuperview()
            if titleLeading {
                $0.width.equalTo(0)
            }
            switch self.layoutOption {
            case .center(let space):
                $0.right.equalToSuperview()
                $0.left.equalTo(leadingView.snp.right).offset(space)
            case .leading(_):
                $0.left.equalTo(leadingView.snp.right).offset(self.alignSpace)
                $0.right.lessThanOrEqualToSuperview()
            case .trailing(_):
                $0.right.equalToSuperview()
                $0.left.equalTo(leadingView.snp.right).offset(self.alignSpace)
            case .leadingTrailing(_, _):
                $0.right.equalToSuperview()
                $0.left.greaterThanOrEqualTo(leadingView.snp.right)
            }
        }
    }
    
    func verticalConstraint(leadingView: UIView, trailingView: UIView, titleLeading: Bool) -> Void {
        
        layoutView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            switch self.layoutOption {
            case .center(_):
                $0.centerY.equalToSuperview()
                $0.height.lessThanOrEqualToSuperview()
            case .leading(let leading):
                $0.top.equalToSuperview().offset(leading)
                $0.bottom.equalToSuperview()
            case .trailing(let trailing):
                $0.top.equalToSuperview()
                $0.bottom.equalToSuperview().offset(-trailing)
            case .leadingTrailing(let leading, let trailing):
                $0.top.equalToSuperview().offset(leading)
                $0.bottom.equalToSuperview().offset(-trailing)
            }
        }
        leadingView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.width.lessThanOrEqualToSuperview()
            if !titleLeading {
                $0.height.equalTo(0)
            }
            switch self.layoutOption {
            case .center(_):
                $0.top.equalToSuperview()
            case .leading(_),
                 .leadingTrailing(_, _):
                $0.top.equalToSuperview()
            case .trailing(_):
                $0.top.greaterThanOrEqualToSuperview()
            }
        }
        trailingView.snp.updateConstraints {
            $0.centerX.equalToSuperview()
            $0.width.lessThanOrEqualToSuperview()
            if titleLeading {
                $0.height.equalTo(0)
            }
            switch self.layoutOption {
            case .center(let space):
                $0.bottom.equalToSuperview()
                $0.top.equalTo(leadingView.snp.bottom).offset(space)
            case .leading(_):
                $0.top.equalTo(leadingView.snp.bottom).offset(self.alignSpace)
                $0.bottom.lessThanOrEqualToSuperview()
            case .trailing(_):
                $0.bottom.equalToSuperview()
                $0.top.equalTo(leadingView.snp.bottom).offset(self.alignSpace)
            case .leadingTrailing(_, _):
                $0.bottom.equalToSuperview()
                $0.top.greaterThanOrEqualTo(leadingView.snp.bottom)
            }
        }
    }
    
    lazy var layoutView: UIView = {
        let temp = UIView()
        temp.isUserInteractionEnabled = false
        addSubview(temp)
        return temp
    }()
    
    lazy var imageView: UIImageView = {
        let temp = UIImageView()
        self.layoutView.addSubview(temp)
        return temp
    }()
    
    public lazy var titleLabel: UILabel = {
        let temp = UILabel()
        temp.textAlignment = .center
        temp.textColor = UIColor.black
        temp.font = UIFont.systemFont(ofSize: 16)
        self.layoutView.addSubview(temp)
        return temp
    }()
}
