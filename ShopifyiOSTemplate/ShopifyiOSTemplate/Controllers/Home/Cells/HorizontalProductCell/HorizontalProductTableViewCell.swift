//
//  HorizontalProductTableViewCell.swift
//  ShopifyiOSTemplate
//
//  Created by Mac on 13/11/21.
//

import UIKit

class ShopifyCategoryProductManager {
    
    var isAllCategoryFetched: Bool = false
    var isCategoryFetching: Bool = false
//    var isProductFetched: [String: Bool] = [:]
    var products: [String: PageableArray<ProductViewModel>] = [:]
    var ratings: [String: (String, Int)] = [:]
    
    fileprivate var collections: PageableArray<CollectionViewModel>?

    static let shared = ShopifyCategoryProductManager()
    
    private init() {}
    
    func fetchProducts(collectionID: String, completion: @escaping () -> Void) {
        
        var afterCursor: String?
        var reverse = ShopifyCategoryProductManager.shared.products[collectionID]?.reverse
        var sortKey = ShopifyCategoryProductManager.shared.products[collectionID]?.sortKey
        
        let isProductFetched = !(ShopifyCategoryProductManager.shared.products[collectionID]?.items.isEmpty ?? true)
        if isProductFetched {
            afterCursor = ShopifyCategoryProductManager.shared.products[collectionID]?.items.last?.cursor
        }
        
        Client.shared.fetchProducts(in: collectionID, after: afterCursor, reverse: reverse, sortKey: sortKey) { products in
            if let products = products {
                if self.products[collectionID] == nil {
                    self.products[collectionID] = products
                } else if let items = self.products[collectionID]?.items, items.isEmpty {
                    self.products[collectionID] = products
                    self.products[collectionID]?.reverse = reverse
                    self.products[collectionID]?.sortKey = sortKey
                } else {
                    self.products[collectionID]?.appendPage(from: products)
                }
                
                let group = DispatchGroup()
                
                for product in products.items {
                    group.enter()
                    let id = Utils.extractProductID(from: product.id) ?? 0
                    ReviewManager.shared.fetchAverageRating(productId: "\(id)") { averageRating, reviewCount, error in
                        if let rating = averageRating, let reviewCount = reviewCount {
                            let formattedRating = String(format: "%.1f", averageRating ?? 0)
                            self.ratings[product.id] = (formattedRating, reviewCount)
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    completion()
                }
            } else {
                completion()
            }
        }
    }
    
    func fetchNextCategory(completion: @escaping () -> Void) {
        if let collections = self.collections,
            let lastCollection = collections.items.last {
            self.isCategoryFetching = true
            Client.shared.fetchCollections(after: lastCollection.cursor) { collections in
                if let collections = collections {
                    self.collections?.appendPage(from: collections)
                    if collections.items.isEmpty {
                        self.isAllCategoryFetched = true
                    }
                }
                self.isCategoryFetching = false
                completion()
            }
        }
    }
}

protocol HorizontalProductTableViewCellDelegate: AnyObject {
    func didSelectAll(collectionID: String, listTitle: String?)
    func didSelectProduct(product: ProductViewModel?)
}

class HorizontalProductTableViewCell: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    var config: HorizontalProductsConfig?
    weak var delegate: HorizontalProductTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setupUI(config: HorizontalProductsConfig?) {
        self.config = config
        
        titleLabel.text = config?.title
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(UINib(nibName: "ProductCellCollectionViewCell", bundle: nil),
                                forCellWithReuseIdentifier: "ProductCellCollectionViewCell")
        
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        
        let isProductFetched = !(ShopifyCategoryProductManager.shared.products[config?.collectionID ?? ""]?.items.isEmpty ?? true)
        
        if !isProductFetched {
            ShopifyCategoryProductManager.shared.fetchProducts(collectionID: config?.collectionID ?? "", completion: { [weak self] in
                self?.collectionView.reloadData()
            })
        }
    }
    
    @IBAction func seeAllAction(_ sender: Any) {
        delegate?.didSelectAll(collectionID: config?.collectionID ?? "", listTitle: config?.title)
    }
}

extension HorizontalProductTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ShopifyCategoryProductManager.shared.products[config?.collectionID ?? ""]?.items.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProductCellCollectionViewCell", for: indexPath) as! ProductCellCollectionViewCell
        let item = ShopifyCategoryProductManager.shared.products[config?.collectionID ?? ""]?.items[indexPath.row]
        let rating = ShopifyCategoryProductManager.shared.ratings[item?.id ?? ""]?.0 ?? ""
        let reviewCount = ShopifyCategoryProductManager.shared.ratings[item?.id ?? ""]?.1 ?? 0
        cell.setupUI(model: item, rating: rating, reviewCount: reviewCount)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = ShopifyCategoryProductManager.shared.products[config?.collectionID ?? ""]?.items[indexPath.row]
        delegate?.didSelectProduct(product: item)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowayout = collectionViewLayout as? UICollectionViewFlowLayout
        let space: CGFloat = (flowayout?.minimumInteritemSpacing ?? 0.0) + (flowayout?.sectionInset.left ?? 0.0) + (flowayout?.sectionInset.right ?? 0.0)
        let size:CGFloat = (collectionView.frame.size.width - space) / 2.5
        return CGSize(width: size, height: size + 45)
    }
}
