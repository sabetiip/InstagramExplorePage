//
//  ViewController.swift
//  ExploreLayout
//
//  Created by Somaye Sabeti on 2/23/21.
//

import UIKit
import AsyncDisplayKit

class ViewController: ASDKViewController<ASCollectionNode> {
    
    var objects: [Post] = []
        
    lazy var adapter: ListAdapter = {
        return ListAdapter(updater: ListAdapterUpdater(), viewController: self, workingRangeSize: 0)
    }()
    
    override init() {
        let exploreLayout = UICollectionViewWeightLayout()
        super.init(node: ASCollectionNode(collectionViewLayout: exploreLayout))
        exploreLayout.itemSpacing = 3
        exploreLayout.numberOfColumns = 3
        exploreLayout.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        adapter.setASDKCollectionNode(node)
        adapter.dataSource = self
        
        testLayoutForInsertItems(count: 100)
        testLayoutInsertAndDelete()
    }
    
    //MARK: - Test
    private func testLayoutForStaticItems() {
        print("Test: ","Static items")
        objects.append(contentsOf: [
            Post(image:"image1", size: .init(width: 1, height: 2)),
            Post(image:"image1", size: .init(width: 2, height: 1)),
            Post(image:"image1", size: .init(width: 1, height: 1)),
            Post(image:"image1", size: .init(width: 2, height: 1)),
            Post(image:"image1", size: .init(width: 2, height: 1)),
            Post(image:"image1", size: .init(width: 1, height: 2)),
            Post(image:"image1", size: .init(width: 2, height: 2)),
            Post(image:"image1", size: .init(width: 2, height: 1)),
        ])
        adapter.performUpdates(animated: false)
        
        testLayoutInsertAndDelete()
    }
    
    private func testLayoutInsertAndDelete() {
        let delay: TimeInterval = 10
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            print("Test: ","Insert after \(delay) seconds")
            self?.testLayoutForInsertItems(count: 20)

//            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
//                print("Test: ","Delete after \(delay) seconds")
//                self?.testLayoutForDeleteItems(count: 3)
//            }
        }
    }
    
    private func testLayoutForInsertItems(count: Int) {
        print("Test: ","Insert \(count) items to \(objects.count) items")
        var list = [Post]()
        for _ in 1 ... count {
            list.append(Post(image: "", size: CGSize(width: Int.random(in: 1...2), height: Int.random(in: 1...2))))
        }
        objects.append(contentsOf: list)
        adapter.performUpdates(animated: false)
        print("Test: Insert these sizes: \(list.map({ $0.size }))")
    }
    
    private func testLayoutForDeleteItems(count: Int) {
        print("Test: ","Delete \(count) items from \(objects.count) items")
        objects.removeSubrange(3...3+count)
        adapter.performUpdates(animated: false)
    }
}

//MARK: - ListAdapterDataSource
extension ViewController: ListAdapterDataSource {
    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        return PostSectionController()
    }
    
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        return objects
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
}

//MARK: - ExploreLayoutDelegate
extension ViewController: UICollectionViewWeightLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, layout weightLayout: UICollectionViewWeightLayout, weightForItemAt indexPath: IndexPath) -> UICollectionViewLayoutWeight {
        let size = objects[indexPath.section].size
        return UICollectionViewLayoutWeight(width: Int(size.width), height: Int(size.height))
    }
}
