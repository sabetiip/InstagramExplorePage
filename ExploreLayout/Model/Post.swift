//
//  Post.swift
//  ExploreLayout
//
//  Created by Somaye Sabeti on 2/23/21.
//

import UIKit

var currentId: Int = 0

class Post: NSObject {
    let id : Int
    let image: String
    let size: CGSize
    
    init(image: String, size: CGSize) {
        self.id = currentId
        currentId = currentId + 1
        self.image = image
        self.size = size
    }
}
