//
//  HTLanguageTableViewCell.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/5.
//

import UIKit

class HTLanguageTableViewCell: UITableViewCell {

    @IBOutlet weak var textLab: UILabel!
    @IBOutlet weak var selectImgV: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
