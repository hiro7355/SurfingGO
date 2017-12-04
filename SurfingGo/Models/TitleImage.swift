//
//  TitleImage.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/25.
//  Copyright © 2017年 ikaika software. All rights reserved.
//

import UIKit

struct TitleImage: Equatable  {
    
    var image: UIImage?
    var titleOfImage: String
    var value : Int
}

func ==(lhs: TitleImage, rhs: TitleImage) -> Bool {
    return lhs.titleOfImage == rhs.titleOfImage
}
