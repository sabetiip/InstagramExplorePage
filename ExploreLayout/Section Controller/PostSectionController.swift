//
//  FinalPostSectionController.swift
//  ExploreLayout
//
//  Created by Somaye Sabeti on 2/24/21.
//

import AsyncDisplayKit

final class PostSectionController: ListSectionController, ASSectionController {
    
    var object: Post?
    
    func nodeBlockForItem(at index: Int) -> ASCellNodeBlock {
        let id = object?.id ?? -1
        return {
            return TextNode(text: "\(id)")
        }
    }
    
    override func numberOfItems() -> Int {
        return 1
    }
    
    override func didUpdate(to object: Any) {
        self.object = object as? Post
    }
    
    override func didSelectItem(at index: Int) {}
    
    override func sizeForItem(at index: Int) -> CGSize {
        return ASIGListSectionControllerMethods.sizeForItem(at: index)
    }
    
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        return ASIGListSectionControllerMethods.cellForItem(at: index, sectionController: self)
    }
}
