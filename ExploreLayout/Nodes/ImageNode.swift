//
//  ImageNode.swift
//  ExploreLayout
//
//  Created by Somaye Sabeti on 2/23/21.
//

import Foundation
import AsyncDisplayKit

class ImageNode: ASCellNode {
    var imageViewNode: ImageViewNode
    
    init(image: String) {
        self.imageViewNode = ImageViewNode(image: image)
        super.init()
        automaticallyManagesSubnodes = true
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(insets: .zero, child: imageViewNode)
    }
}

final class ImageViewNode: ASDisplayNode {
        
    var image: String
    
    init(image: String) {
        self.image = image
        super.init()
        setViewBlock({ UIImageView() })
    }
    
    var imageView: UIImageView {
        return view as! UIImageView
    }
    
    override func didLoad() {
        super.didLoad()
        imageView.image = UIImage(named: image)
    }
}

