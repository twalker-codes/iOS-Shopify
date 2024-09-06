//
//  ProductListViewController.swift
//  ShopifyiOSTemplate
//
//  Created by Mac on 15/11/21.
//

import UIKit

class ProductListViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    var collectionID: String = ""
    var listTitle: String? = ""
    @IBOutlet weak var emptyStateView: UIView!
    var emptyStateVC: EmptyStateViewController?

    let inset: CGFloat = 10
    let minimumLineSpacing: CGFloat = 10
    let minimumInteritemSpacing: CGFloat = 10
    let cellsPerRow = 2
    var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = listTitle
        setupUI(collectionID: collectionID)
        
        setupNavigationBar()
        // Do any additional setup after loading the view.
    }
    
    func setupNavigationBar() {
        let filterButton = UIBarButtonItem(image: UIImage(systemName: "line.horizontal.3.decrease.circle"), style: .plain, target: self, action: #selector(showFilterActionSheet))
        navigationItem.rightBarButtonItem = filterButton
    }

    @objc func showFilterActionSheet() {
        presentFilterActionSheet()
    }
    
    func presentFilterActionSheet() {
        let actionSheet = UIAlertController(title: "Sort Products", message: "Choose a sorting option", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Title", style: .default, handler: { [weak self] _ in
            self?.applySorting(sortKey: .title)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Price: Low to High", style: .default, handler: { [weak self] _ in
            self?.applySorting(sortKey: .price, reverse: false)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Price: High to Low", style: .default, handler: { [weak self] _ in
            self?.applySorting(sortKey: .price, reverse: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Best Selling", style: .default, handler: { [weak self] _ in
            self?.applySorting(sortKey: .bestSelling)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    func applySorting(sortKey: ProductSortKey?, reverse: Bool? = nil) {
        ShopifyCategoryProductManager.shared.products[collectionID]?.items = []
        ShopifyCategoryProductManager.shared.products[collectionID]?.sortKey = sortKey
        ShopifyCategoryProductManager.shared.products[collectionID]?.reverse = reverse
        self.collectionView.reloadData()
        self.loadProducts(collectionID: collectionID)
    }
    
    func setupUI(collectionID: String) {
        self.collectionID = collectionID
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(UINib(nibName: "ProductCellCollectionViewCell", bundle: nil),
                                forCellWithReuseIdentifier: "ProductCellCollectionViewCell")
        
        let isProductFetched = !(ShopifyCategoryProductManager.shared.products[collectionID]?.items.isEmpty ?? true)
        
        if !isProductFetched {
            self.loadProducts(collectionID: collectionID)
        }
    }
    
    func loadProducts(collectionID: String) {
        isLoading = true
        ShopifyCategoryProductManager.shared.fetchProducts(collectionID: collectionID, completion: { [weak self] in
            self?.isLoading = false
            self?.collectionView.reloadData()
            let products = ShopifyCategoryProductManager.shared.products[collectionID]?.items
            if (products?.isEmpty ?? (products == nil)) {
                self?.emptyStateView.isHidden = false
                self?.emptyStateVC?.emptyTitle = "No Products Found"
                self?.emptyStateVC?.emptyMessage = "There are no products found under this collection"
            }
        })
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        // Check if the user has scrolled to the bottom
        if offsetY > contentHeight - height * 2 {
            guard !isLoading else { return }
            loadProducts(collectionID: collectionID)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "emptyStateSegue", let destinationVC = segue.destination as? EmptyStateViewController {
            self.emptyStateVC = destinationVC
        }
    }
}

extension ProductListViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // UICollectionViewDelegateFlowLayout confirm this to viewcontroller
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return minimumLineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return minimumInteritemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let marginsAndInsets = inset * 2 + collectionView.safeAreaInsets.left + collectionView.safeAreaInsets.right + minimumInteritemSpacing * CGFloat(cellsPerRow - 1)
        let itemWidth = ((collectionView.bounds.size.width - marginsAndInsets) / CGFloat(cellsPerRow)).rounded(.down)
        return CGSize(width: itemWidth, height: itemWidth + 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ShopifyCategoryProductManager.shared.products[collectionID]?.items.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProductCellCollectionViewCell", for: indexPath) as! ProductCellCollectionViewCell
        let item = ShopifyCategoryProductManager.shared.products[collectionID]?.items[indexPath.row]        
        let rating = ShopifyCategoryProductManager.shared.ratings[item?.id ?? ""]?.0 ?? ""
        let reviewCount = ShopifyCategoryProductManager.shared.ratings[item?.id ?? ""]?.1 ?? 0
        cell.setupUI(model: item, rating: rating, reviewCount: reviewCount, showWishList: true)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let productDetailViewController = storyboard?.instantiateViewController(withIdentifier: "ProductDetailViewController") as! ProductDetailViewController
        let product = ShopifyCategoryProductManager.shared.products[collectionID]?.items[indexPath.row]
        productDetailViewController.productID = product?.id ?? ""
        self.navigationController?.pushViewController(productDetailViewController, animated: true)
    }
}
