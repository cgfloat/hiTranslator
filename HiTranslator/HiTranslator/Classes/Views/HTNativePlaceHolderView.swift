//
//  HTNativePlaceHolderView.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/21.
//

import UIKit

class HTNativePlaceHolderView: UIView {

    @objc class func loadFromXib() -> HTNativePlaceHolderView {
        let header = Bundle.main.loadNibNamed("HTNativePlaceHolderView", owner: nil, options: nil)?.first as! HTNativePlaceHolderView
        header.frame = CGRect(x: 0, y: 56 + status_height, width: screen_width, height: 60)
        return header
    }

}
