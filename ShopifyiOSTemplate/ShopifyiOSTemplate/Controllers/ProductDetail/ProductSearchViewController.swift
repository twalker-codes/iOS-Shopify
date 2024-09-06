//
//  ProductSearchViewController.swift
//  ShopifyiOSTemplate
//
//  Created by Mac on 22/11/21.
//

import UIKit

class ProductSearchViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchTextField: UITextField!
    var products: PageableArray<ProductViewModel>?
    var ratings: [String: (String, Int)] = [:] // Store ratings and review counts
    var debounceTimer: Timer?
    var isLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Find Products"
        
        searchTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)

        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(UINib(nibName: "ProductCellCollectionViewCell", bundle: nil),
                                forCellWithReuseIdentifier: "ProductCellCollectionViewCell")

        searchTextField.becomeFirstResponder()
        // Do any additional setup after loading the view.
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        debounceTimer?.invalidate() // Invalidate any existing timer
        
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] timer in
            guard let self = self else { return }
            
            guard let searchTerm = textField.text, !searchTerm.isEmpty else {
                self.products = nil // Clear products if the search term is empty
                self.collectionView.reloadData()
                return
            }
            
            self.products = nil
            self.fetchProducts(searchTerm: searchTerm)
        }
    }
    
    func fetchProducts(searchTerm: String) {
        
        var afterCursor: String?
        
        let isProductFetched = !(self.products?.items.isEmpty ?? true)
        if isProductFetched {
            afterCursor = self.products?.items.last?.cursor
        }
        
        isLoading = true
        
        Client.shared.fetchProducts(searchTerm: searchTerm, after: afterCursor) { products in
            self.isLoading = false
            
            guard let products = products else { return }

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
                if self.products == nil {
                    self.products = products
                } else {
                    self.products?.appendPage(from: products)
                }
                self.collectionView.reloadData()
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        // Check if the user has scrolled to the bottom
        if offsetY > contentHeight - height * 2 {
            guard !isLoading else { return }
            self.fetchProducts(searchTerm: searchTextField.text ?? "")
        }
    }
}

extension ProductSearchViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return products?.items.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProductCellCollectionViewCell", for: indexPath) as! ProductCellCollectionViewCell
        let item = products?.items[indexPath.row]
        let rating = ShopifyCategoryProductManager.shared.ratings[item?.id ?? ""]?.0 ?? ""
        let reviewCount = ShopifyCategoryProductManager.shared.ratings[item?.id ?? ""]?.1 ?? 0
        cell.setupUI(model: item, rating: rating, reviewCount: reviewCount)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let productDetailViewController = storyboard?.instantiateViewController(withIdentifier: "ProductDetailViewController") as! ProductDetailViewController
        let product = products?.items[indexPath.row]
        productDetailViewController.productID = product?.id ?? ""
        self.navigationController?.pushViewController(productDetailViewController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowayout = collectionViewLayout as? UICollectionViewFlowLayout
        let space: CGFloat = (flowayout?.minimumInteritemSpacing ?? 0.0) + (flowayout?.sectionInset.left ?? 0.0) + (flowayout?.sectionInset.right ?? 0.0)
        let size:CGFloat = (collectionView.frame.size.width - space) / 2.0
        return CGSize(width: size, height: size)
    }
}
