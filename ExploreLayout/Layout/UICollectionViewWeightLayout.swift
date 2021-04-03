import UIKit

public protocol UICollectionViewWeightLayoutDelegate: class {
    func collectionView(_ collectionView: UICollectionView, layout weightLayout: UICollectionViewWeightLayout, weightForItemAt indexPath: IndexPath) -> UICollectionViewLayoutWeight
}

private struct UICollectionViewWeightLayoutPoint {
    let row: Int
    let column: Int
    
    init(column: Int, row: Int) {
        self.row = row
        self.column = column
    }
}

public struct UICollectionViewLayoutWeight: Equatable {
    public let width: Int
    public let height: Int
    
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

private struct UICollectionViewWeightLayoutPosition {
    let origin: UICollectionViewWeightLayoutPoint
    let weight: UICollectionViewLayoutWeight
    
    init(origin: UICollectionViewWeightLayoutPoint, weight: UICollectionViewLayoutWeight) {
        self.origin = origin
        self.weight = weight
    }
}

public class UICollectionViewWeightLayout: UICollectionViewLayout {
    public var itemSpacing: CGFloat = 0
    public var numberOfColumns: Int = 1
    public weak var delegate: UICollectionViewWeightLayoutDelegate?

    private var contentWidth: CGFloat = 0
    private var contentHeight: CGFloat = 0
    private var itemDimension: CGFloat = 0
    private var firstVacantRowIndex: Int = 0
    private var positions: [UICollectionViewWeightLayoutPosition] = []

    /// This represents a 2 dimensional array, indicating whether each block in the grid is occupied
    /// It is grown dynamically as needed to fit every item into a grid
    private var occupationMap = [[Bool]]()

    /// The cache built up during the `prepare` function
    private var itemAttributesCache: Array<UICollectionViewLayoutAttributes> = []

    // MARK: - UICollectionView Layout
    public override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    public override func prepare() {
        // On rotation, UICollectionView sometimes calls prepare without calling invalidateLayout
        guard itemAttributesCache.isEmpty, let collectionView = collectionView, collectionView.numberOfSections > 0 else {
            return
        }

        let date = Date()
        
        let fixedDimension: CGFloat = collectionView.frame.width - (collectionView.contentInset.left + collectionView.contentInset.right)
        contentWidth = fixedDimension
        itemDimension = (fixedDimension - (CGFloat(numberOfColumns) * itemSpacing) + itemSpacing) / CGFloat(numberOfColumns)
        
        var mustReset = false
        var indexPathes: [IndexPath] = []
        for section in 0 ..< collectionView.numberOfSections {
            for item in 0 ..< collectionView.numberOfItems(inSection: section) {
                indexPathes.append(IndexPath(item: item, section: section))
            }
        }
        for (itemIndex, indexPath) in indexPathes.enumerated() {
            let mustCalculate: Bool
            let weight = delegate?.collectionView(collectionView, layout: self, weightForItemAt: indexPath) ?? UICollectionViewLayoutWeight(width: 0, height: 0)
            
            if itemIndex < positions.count {
                if positions[itemIndex].weight != weight {
                    if itemIndex < Int((Double(positions.count) * 0.2)) {
                        mustReset = true
                        break
                    } else {
                        mustCalculate = true
                        // free occupied points in occupation map and update firstVacantRowIndex
                        for index in itemIndex ..< positions.count {
                            let position = positions[index]
                            for row in position.origin.row ..< position.origin.row + position.weight.height {
                                for column in position.origin.column ..< position.origin.column + position.weight.width {
                                    occupationMap[row][column] = false
                                    if firstVacantRowIndex > row {
                                        firstVacantRowIndex = row
                                    }
                                }
                            }
                        }
                        // delete empty rows in occupation map (from buttom to top) and update firstVacantRowIndex
                        let count = occupationMap.count
                        for index in firstVacantRowIndex ..< count {
                            let reverseIndex = count - 1 - index
                            if !occupationMap[reverseIndex].contains(true) {
                                occupationMap.remove(at: reverseIndex)
                            }else{
                                break
                            }
                        }
                        if firstVacantRowIndex > occupationMap.count {
                            firstVacantRowIndex = occupationMap.count
                        }
                        // delete related positions in postitions cache
                        positions.removeLast(positions.count - itemIndex)
                    }
                }else{
                    mustCalculate = false
                }
            } else {
                mustCalculate = true
            }
            
            let itemAttributes: UICollectionViewLayoutAttributes
            let position: UICollectionViewWeightLayoutPosition
            if mustCalculate {
                let resultPosition = layoutPosition(for: weight)
                positions.append(resultPosition)
                position = resultPosition
            } else {
                position = positions[itemIndex]
            }
            itemAttributes = layoutAttributes(for: indexPath, position: position)
            itemAttributesCache.append(itemAttributes)
            
            // Update flexible dimension
            if itemAttributes.frame.maxY > contentHeight {
                contentHeight = itemAttributes.frame.maxY
            }
        }
        if mustReset {
            firstVacantRowIndex = 0
            occupationMap = []
            positions = []
            reset()
            prepare()
        }
        let seconds = Date().timeIntervalSince1970 - date.timeIntervalSince1970
        if seconds > 1 {
            assertionFailure("UICollectionViewWeightLayout: Prepare took \(seconds) seconds.")
        }else if seconds > 0.1 {
            print("UICollectionViewWeightLayout: Prepare took \(seconds) seconds.")
        }
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let itemAttributes = itemAttributesCache.filter {
            $0.frame.intersects(rect)
        }

        return itemAttributes
    }

    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if let oldWidth = collectionView?.bounds.width {
            return oldWidth != newBounds.width
        }
        return false
    }

    public override func invalidateLayout() {
        super.invalidateLayout()
        reset()
    }
    
    // MARK: - Private
    private func reset() {
        itemAttributesCache = []
        contentWidth = 0
        contentHeight = 0
    }
    
    private func layoutAttributes(for indexPath: IndexPath, position: UICollectionViewWeightLayoutPosition) -> UICollectionViewLayoutAttributes {
        let layoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        let fixedIndexOffset = CGFloat(position.origin.column) * (itemSpacing + itemDimension)
        let longitudinalOffset = CGFloat(position.origin.row) * (itemSpacing + itemDimension)
        let itemScaledTransverseDimension = itemDimension + (CGFloat(position.weight.width - 1) * (itemSpacing + itemDimension))
        let itemScaledLongitudinalDimension = itemDimension + (CGFloat(position.weight.height - 1) * (itemSpacing + itemDimension))
        layoutAttributes.frame = CGRect(x: fixedIndexOffset, y: longitudinalOffset, width: itemScaledTransverseDimension, height: itemScaledLongitudinalDimension)
        return layoutAttributes
    }
    
    private func layoutPosition(for weight: UICollectionViewLayoutWeight) -> UICollectionViewWeightLayoutPosition {
        let vacantSlice = occupationMap[firstVacantRowIndex..<occupationMap.count]
        let candidatePoints = vacantSlice.enumerated()
            .map { (sliceIndex, element) -> [UICollectionViewWeightLayoutPoint] in
                let row = sliceIndex + firstVacantRowIndex
                return element.enumerated()
                    .filter {
                        !$0.element
                    }
                    .filter { column in
                        if weight.width > 1 {
                            if column.offset <= (numberOfColumns - weight.width) {
                                return true
                            } else {
                                return false
                            }
                        }
                        return true
                    }
                    .filter { column in
                        if weight.height > 1 {
                            if row <= (occupationMap.count - weight.height) {
                                return true
                            } else {
                                return false
                            }
                        }
                        return true
                    }
                    .map { column in
                        UICollectionViewWeightLayoutPoint(column: column.offset, row: row)
                    }
            }
            .flatMap { $0 }
        
        if candidatePoints.isEmpty {
            occupationMap.append(Array(repeating: false, count: numberOfColumns))
            return layoutPosition(for: weight)
        } else {
            for candidatePoint in candidatePoints {
                var isOccupied = false
                var needToFillPoints: [UICollectionViewWeightLayoutPoint] = []
                outer: for row in candidatePoint.row ..< (candidatePoint.row + weight.height) {
                    for column in candidatePoint.column ..< (candidatePoint.column + weight.width) {
                        needToFillPoints.append(UICollectionViewWeightLayoutPoint(column: column, row: row))
                        if occupationMap[row][column] {
                            isOccupied = true
                            break outer
                        }
                    }
                }
                if !isOccupied {
                    for point in needToFillPoints {
                        occupationMap[point.row][point.column] = true
                    }
                    var updatedFirstVacantRowIndex: Int?
                    for row in firstVacantRowIndex ..< occupationMap.count {
                        if occupationMap[row].contains(false) {
                            updatedFirstVacantRowIndex = row
                            break
                        }
                    }
                    if let updatedFirstVacantRowIndex = updatedFirstVacantRowIndex {
                        firstVacantRowIndex = updatedFirstVacantRowIndex
                    }else{
                        firstVacantRowIndex = occupationMap.count
                    }
                    return UICollectionViewWeightLayoutPosition(origin: candidatePoint, weight: weight)
                }
            }
            // none of the candidates was fully vacant to place, adding a new row and retry
            occupationMap.append(Array(repeating: false, count: numberOfColumns))
            return layoutPosition(for: weight)
        }
    }
}
