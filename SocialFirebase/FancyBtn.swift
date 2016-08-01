//
//  FancyBtn.swift
//  SocialFirebase
//
//  Created by Brian Park on 7/31/16.
//  Copyright © 2016 Brian Park. All rights reserved.
//

import UIKit

class FancyBtn: UIButton {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.shadowColor = UIColor(red: SHADOW_GRAY, green: SHADOW_GRAY, blue: SHADOW_GRAY, alpha: 0.6).CGColor
        layer.shadowOpacity = 0.8
        layer.shadowRadius = 5.0
        layer.cornerRadius = 2.0
    }
}
