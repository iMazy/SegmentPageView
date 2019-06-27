//
//  SegmentTitleView.swift
//  SegmentPageView
//
//  Created by Mazy on 2019/6/24.
//  Copyright © 2019 Mazy. All rights reserved.
//

import UIKit

enum IndicatorType {
    case `default`
    case equalTitle
    case custom
    case width
    case none
}

protocol SegmentTitleViewDelegate: NSObjectProtocol {
    
    /// 切换标题
    ///   - startIndex: 切换前标题索引
    ///   - endIndex: 切换后标题索引
    func segmentTitleView(_ titleView: SegmentTitleView, startIndex: Int, endIndex: Int)
    
}

class SegmentTitleView: UIView {
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.scrollsToTop = false
        return scrollView
    }()
    private var itemButtons: [UIButton] = []
    private var indicatorView: UIView = UIView()
    private var bottomLineView: UIView = UIView()
    private var indicatorType: IndicatorType = .default
    private var isInitinaled: Bool = false
    
    weak var delegate: SegmentTitleViewDelegate?
    /// 标题
    private var titles: [String] = []
    // 属性
    private var property: SegmentTitleProperty!
    
    /// 当前选中标题索引，默认0
    var selectIndex: Int = 0 {
        didSet {
            if selectIndex < 0 || selectIndex > itemButtons.count - 1 {
                return
            }
            itemButtons.forEach({ $0.isSelected = false })
            let currentButton = scrollView.viewWithTag(selectIndex + 666) as! UIButton
            currentButton.isSelected = true
            currentButton.titleLabel?.font = property.titleSelectFont
            setNeedsLayout()
            layoutIfNeeded()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, titles: [String], property: SegmentTitleProperty, indicatorType: IndicatorType) {
        self.init(frame: frame)
        
        scrollView.addSubview(bottomLineView)
        scrollView.addSubview(indicatorView)
        self.addSubview(scrollView)
        
        self.titles = titles
        self.property = property
        self.indicatorType = indicatorType
        
        setupTitles()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTitles() {
        
        indicatorView.backgroundColor = property.indicatorColor
        
        for title in titles {
            let button = UIButton(type: .custom)
            button.tag = self.itemButtons.count + 666
            button.setTitle(title, for: .normal)
            button.setTitleColor(property.titleNormalColor, for: .normal)
            button.setTitleColor(property.titleSelectColor, for: .selected)
            button.titleLabel?.font = property.titleNormalFont
            self.scrollView.addSubview(button)
            button.addTarget(self, action: #selector(buttonClickAction(sender:)), for: .touchUpInside)
            if itemButtons.count == selectIndex {
                button.isSelected  = true
            }
            button.sizeToFit()
            itemButtons.append(button)
        }
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    @objc func buttonClickAction(sender: UIButton) {
        let index = sender.tag - 666
        if index == self.selectIndex {
            return
        }
        self.delegate?.segmentTitleView(self, startIndex: self.selectIndex, endIndex: index)
        self.selectIndex = index
        
        moveIndicatorView(animated: true)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.scrollView.frame = self.bounds
        if self.itemButtons.count <= 0 {
            return
        }
        
        var totalButtonWidth: CGFloat = 0
        
        if property.titleNormalFont != property.titleSelectFont {
            for (i, title) in titles.enumerated() {
                let button = itemButtons[i]
                let titleFont  = button.isSelected ? property.titleSelectFont : property.titleNormalFont
                let itemButtonWidth = title.widthOfString(usingFont: titleFont) + property.itemMargin
                totalButtonWidth += itemButtonWidth
            }
        } else {
            for title in titles {
                let itemButtonWidth = title.widthOfString(usingFont: property.titleNormalFont) + property.itemMargin
                totalButtonWidth += itemButtonWidth
            }
        }
        
        if totalButtonWidth <= self.bounds.width { // //不能滑动
            if property.isLeft {
                var currentX: CGFloat = 0
                for (i, title) in titles.enumerated() {
                    let button = itemButtons[i]
                    let titleFont = button.isSelected ? property.titleSelectFont : property.titleNormalFont
                    let itemButtonWidth = title.widthOfString(usingFont: titleFont) + property.itemMargin
                    let itemButtonHeight = self.bounds.height
                    button.frame = CGRect(x: currentX, y: 0, width: itemButtonWidth, height: itemButtonHeight)
                    currentX += itemButtonWidth
                }
                scrollView.contentSize = CGSize(width: currentX, height: scrollView.bounds.height)
            } else {
                let itemButtonWidth = self.bounds.width / CGFloat(itemButtons.count)
                let itemButtonHeight = self.bounds.height
                itemButtons.enumerated().forEach { (index, button) in
                    button.frame = CGRect(x: CGFloat(index) * itemButtonWidth, y: 0, width: itemButtonWidth, height: itemButtonHeight)
                }
                scrollView.contentSize = CGSize(width: self.bounds.width, height: scrollView.bounds.height)
            }
        } else { //超出屏幕 可以滑动
            var currentX: CGFloat = 0
            for (i, title) in titles.enumerated() {
                let button = itemButtons[i]
                let titleFont  = button.isSelected ? property.titleSelectFont : property.titleNormalFont
                let itemButtonWidth = title.widthOfString(usingFont: titleFont) + property.itemMargin
                let itemButtonHeight = self.bounds.height
                button.frame = CGRect(x: currentX, y: 0, width: itemButtonWidth, height: itemButtonHeight)
                currentX += itemButtonWidth
            }
            scrollView.contentSize = CGSize(width: currentX, height: self.scrollView.bounds.height)
        }
        
        bottomLineView.backgroundColor = property.bottomLineColor
        bottomLineView.isHidden = !property.showBottomLine
        if property.showBottomLine {
            bottomLineView.frame = CGRect(x: 0, y: scrollView.bounds.height - property.bottomLineHeight, width: scrollView.bounds.width, height: property.bottomLineHeight)
            scrollView.bringSubviewToFront(bottomLineView)
        }
        
        moveIndicatorView(animated: isInitinaled)
    }
    
    /// 移动指示器
    ///
    /// - Parameter animated: 是否有动画
    func moveIndicatorView(animated: Bool) {
        let selectButton = itemButtons[selectIndex]
        let titleFont = selectButton.isSelected ? property.titleSelectFont : property.titleNormalFont
        let indicatorWidth = titles[selectIndex].widthOfString(usingFont: titleFont)
        
        let scrollViewHeight = scrollView.bounds.height
        let bottonOffset = property.showBottomLine ? property.bottomLineHeight : 0
        UIView.animate(withDuration: animated ? 0.25 : 0, animations: {
            switch self.indicatorType {
            case .default:
                self.indicatorView.frame = CGRect(x: selectButton.frame.origin.x, y: scrollViewHeight - self.property.indicatorHeight - bottonOffset,
                                                  width: selectButton.bounds.width, height: self.property.indicatorHeight)
            case .equalTitle:
                self.indicatorView.center = CGPoint(x: selectButton.center.x, y: scrollViewHeight - self.property.indicatorHeight - bottonOffset)
                self.indicatorView.bounds = CGRect(x: 0, y: 0, width: indicatorWidth, height: self.property.indicatorHeight)
            case .custom:
                self.indicatorView.center = CGPoint(x: selectButton.center.x, y: scrollViewHeight - self.property.indicatorHeight - bottonOffset)
                self.indicatorView.bounds = CGRect(x: 0, y: 0, width: indicatorWidth + self.property.indicatorExtension * 2,
                                                   height: self.property.indicatorHeight)
            case .width:
                self.indicatorView.center = CGPoint(x: selectButton.center.x, y: scrollViewHeight - self.property.indicatorHeight - bottonOffset)
                self.indicatorView.bounds = CGRect(x: 0, y: 0, width: self.property.indicatorExtension, height: self.property.indicatorHeight)
            case .none:
                self.indicatorView.frame = .zero
            }
        }, completion: { _ in
            self.scrollSelectButtonCenter(animated: animated)
            self.isInitinaled = true
        })
    }
    
    private func scrollSelectButtonCenter(animated: Bool) {
        let selectButton = itemButtons[selectIndex]
        let centerRect = CGRect(x: selectButton.center.x - scrollView.bounds.width / 2, y: 0,
                                width: scrollView.bounds.width, height: scrollView.bounds.height)
        scrollView.scrollRectToVisible(centerRect, animated: animated)
    }
}

private extension String {
    
    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }
    
    func heightOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.height
    }
    
    func sizeOfString(usingFont font: UIFont) -> CGSize {
        let fontAttributes = [NSAttributedString.Key.font: font]
        return self.size(withAttributes: fontAttributes)
    }
}