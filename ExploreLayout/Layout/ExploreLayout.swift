//
//  ExploreLayout.swift
//  ExploreLayout
//
//  Created by Somaye Sabeti on 2/24/21.
//

import UIKit

protocol ExploreLayoutDelegate: class {
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
}

extension ExploreLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 1, height: 1)
    }
}

class ExploreLayout: UICollectionViewLayout, ExploreLayoutDelegate {
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    var scrollDirection: UICollectionView.ScrollDirection = .vertical
    var itemSpacing: CGFloat = 0
    var numberOfColumns: UInt {
        get {
            return UInt(intNumberOfColumns)
        }
        set {
            intNumberOfColumns = newValue == 0 ? 1 : Int(newValue)
        }
    }

    weak var delegate: ExploreLayoutDelegate?

    private var intNumberOfColumns = 1
    private var contentWidth: CGFloat = 0
    private var contentHeight: CGFloat = 0
    private var itemDimension: CGFloat = 0
    private var lastIndexOfOccupationMap = 0
    private var positions = [(size: CGSize, position: CGPoint)]()

    /// This represents a 2 dimensional array for each section, indicating whether each block in the grid is occupied
    /// It is grown dynamically as needed to fit every item into a grid
    private var occupationMap = [[Bool]]()

    /// The cache built up during the `prepare` function
    private var itemAttributesCache: Array<UICollectionViewLayoutAttributes> = []

    // MARK: - UICollectionView Layout

    override func prepare() {
        // On rotation, UICollectionView sometimes calls prepare without calling invalidateLayout
        guard itemAttributesCache.isEmpty, let collectionView = collectionView, collectionView.numberOfSections > 0 else { return }

        let date = Date()
        print("Test: ","Prepare Layout Start")
        
        let fixedDimension: CGFloat
        if scrollDirection == .vertical {
            fixedDimension = collectionView.frame.width - (collectionView.contentInset.left + collectionView.contentInset.right)
            contentWidth = fixedDimension
        } else {
            fixedDimension = collectionView.frame.height - (collectionView.contentInset.top + collectionView.contentInset.bottom)
            contentHeight = fixedDimension
        }

        itemDimension = (fixedDimension - (CGFloat(numberOfColumns) * itemSpacing) + itemSpacing) / CGFloat(numberOfColumns)
        
        var mustCalculate = false
        for section in 0 ..< collectionView.numberOfSections {
            let itemCount = collectionView.numberOfItems(inSection: section)
            
            // Calculate item attributes
            for i in 0 ..< itemCount {
                let itemIndexPath = IndexPath(item: i, section: section)
                let size = (delegate ?? self).collectionView(collectionView, layout: self, sizeForItemAt: itemIndexPath)
                
                if section < positions.count {
                    if section < Int((Double(positions.count) * 0.2)) {
                        mustCalculate = true

                        occupationMap = [[Bool]]()
                        positions = []
                        lastIndexOfOccupationMap = 0
                        
                    } else {
                        if positions[section].size != size {
                            mustCalculate = true
                            
                            var isFirstAssignLastIndexDuringUpdate = true
                            for indexPos in section ..< positions.count {
                                let posItem = positions[indexPos]
                                for i in Int(posItem.position.y) ..< Int(posItem.position.y + posItem.size.height) {
                                    for j in Int(posItem.position.x) ..< Int(posItem.position.x + posItem.size.width) {
                                        occupationMap[i][j] = false
                                        if isFirstAssignLastIndexDuringUpdate {
                                            lastIndexOfOccupationMap = i
                                            isFirstAssignLastIndexDuringUpdate = false
                                        } else {
                                            if lastIndexOfOccupationMap > i {
                                                lastIndexOfOccupationMap = i
                                            }
                                        }
                                    }
                                }
                            }
                            positions.removeLast(positions.count - section)
                        }
                    }
                } else {
                    mustCalculate = true
                }
                
                var itemAttributes: UICollectionViewLayoutAttributes!
                if mustCalculate {
                    let result = checkIsValidSpace(size: size)
                    itemAttributes = layoutAttributes(for: itemIndexPath, size: size, position: result.position)
                    itemAttributesCache.append(itemAttributes)
                    positions.append((size, result.position))
                } else {
                    itemAttributes = layoutAttributes(for: itemIndexPath, size: size, position: positions[section].position)
                    itemAttributesCache.append(itemAttributes)
                }
                
                // Update flexible dimension
                if scrollDirection == .vertical {
                    if itemAttributes.frame.maxY > contentHeight {
                        contentHeight = itemAttributes.frame.maxY
                    }
                } else {
                    if itemAttributes.frame.maxX > contentWidth {
                        contentWidth = itemAttributes.frame.maxX
                    }
                }
            }
        }
        print("Test: ","Prepare Layout End With Time: \(Date().timeIntervalSince1970 - date.timeIntervalSince1970)")
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let itemAttributes = itemAttributesCache.filter {
            $0.frame.intersects(rect)
        }

        return itemAttributes
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if scrollDirection == .vertical, let oldWidth = collectionView?.bounds.width {
            return oldWidth != newBounds.width
        } else if scrollDirection == .horizontal, let oldHeight = collectionView?.bounds.height {
            return oldHeight != newBounds.height
        }

        return false
    }

    override func invalidateLayout() {
        super.invalidateLayout()

        itemAttributesCache = []
        lastIndexOfOccupationMap = 0
        contentWidth = 0
        contentHeight = 0
    }

    // MARK: - Private
    private func layoutAttributes(for indexPath: IndexPath, size: CGSize, position: CGPoint) -> UICollectionViewLayoutAttributes {
        let layoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        
        let fixedIndexOffset = CGFloat(position.x) * (itemSpacing + itemDimension)
        let longitudinalOffset = CGFloat(position.y) * (itemSpacing + itemDimension)
        let itemScaledTransverseDimension = itemDimension + (CGFloat(size.width - 1) * (itemSpacing + itemDimension))
        let itemScaledLongitudinalDimension = itemDimension + (CGFloat(size.height - 1) * (itemSpacing + itemDimension))

        if scrollDirection == .vertical {
            layoutAttributes.frame = CGRect(x: fixedIndexOffset, y: longitudinalOffset, width: itemScaledTransverseDimension, height: itemScaledLongitudinalDimension)
        } else {
            layoutAttributes.frame = CGRect(x: longitudinalOffset, y: fixedIndexOffset, width: itemScaledLongitudinalDimension, height: itemScaledTransverseDimension)
        }

        return layoutAttributes
    }
    
    private func checkIsValidSpace(size: CGSize) -> (size: CGSize, position: CGPoint) {
        let myOccupation = occupationMap[lastIndexOfOccupationMap ..< occupationMap.count]
        let indicesOfFalse = myOccupation.enumerated()
            .map {
                top in top.element.enumerated()
                    .filter {_ in
                        (top.offset + lastIndexOfOccupationMap) >= lastIndexOfOccupationMap
                    }
                    .filter {
                        !$0.element
                    }
                    .filter {
                        if size.width > 1 {
                            if $0.offset <= (intNumberOfColumns - Int(size.width)) {
                                return true
                            } else {
                                return false
                            }
                        }
                        return true
                    }
                    .filter {_ in
                        if size.height > 1 {
                            if (top.offset + lastIndexOfOccupationMap) <= (occupationMap.count - Int(size.height)) {
                                return true
                            } else {
                                return false
                            }
                        }
                        return true
                    }
                    .map {
                        (x: $0.offset, y: (top.offset + lastIndexOfOccupationMap))
                    }
            }
            .filter { $0.count > 0 }
            .flatMap { $0 }
        
        if indicesOfFalse.isEmpty {
            occupationMap.append(Array(repeating: false, count: intNumberOfColumns))
            return checkIsValidSpace(size: size)
            
        } else {
            for indice in indicesOfFalse {
                var isFill = false
                var needToFillIndices: [(Int, Int)] = []
                outer: for i in indice.y ..< (indice.y + Int(size.height)) {
                    for j in indice.x ..< (indice.x + Int(size.width)) {
                        needToFillIndices.append((i, j))
                        if occupationMap[i][j] {
                            isFill = true
                            break outer
                        }
                    }
                }
                if !isFill {
                    for (y, x) in needToFillIndices {
                        occupationMap[y][x] = true
                    }
                    for i in lastIndexOfOccupationMap ..< occupationMap.count {
                        if occupationMap[i].contains(false) {
                            lastIndexOfOccupationMap = i
                            break
                        }
                    }
                    return (size: size, position: CGPoint(x: indice.x, y: indice.y))
                }
            }
        }
        occupationMap.append(Array(repeating: false, count: intNumberOfColumns))
        return checkIsValidSpace(size: size)
    }
}

