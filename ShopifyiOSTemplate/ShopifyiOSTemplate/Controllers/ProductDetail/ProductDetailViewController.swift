//
//  ProductDetailViewController.swift
//  ShopifyiOSTemplate
//
//  Created by Mac on 15/11/21.
//

import UIKit
import FSPagerView
import MobileBuySDK
import WebKit
import CoreData
import SVProgressHUD
import Cosmos

enum VariantAvailability: String {
    case AddedToCart
    case AddToCart
    case OutOfStock
}

class ProductDetailViewController: UIViewController {

    fileprivate var productImageUrls: [String] = []
    private var product: ProductViewModel?
    var productID = ""
    var judgeMeProductID: Int?

    @IBOutlet weak var pagerView: FSPagerView! {
        didSet {
            self.pagerView.register(FSPagerViewCell.self, forCellWithReuseIdentifier: "cell")
        }
    }
    
    @IBOutlet weak var pageControl: FSPageControl! {
        didSet {
            self.pageControl.numberOfPages = self.productImageUrls.count
            self.pageControl.contentHorizontalAlignment = .center
            self.pageControl.contentInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            self.pageControl.hidesForSinglePage = true
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var optionsTableView: UITableView!
    @IBOutlet weak var addToCartButton: UIButton!
    @IBOutlet weak var optionsTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var descriptionWebView: WKWebView!
    @IBOutlet weak var descriptionWebViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var wishListContainerView: UIView!
    @IBOutlet weak var wishListIcon: UIImageView!
    @IBOutlet weak var selectVariantLabel: UILabel!
    @IBOutlet weak var rateButton: UIButton!
    @IBOutlet weak var rateTitleLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var ratingAverageLabel: UILabel!
    @IBOutlet weak var reviewCountLabel: UILabel!
    @IBOutlet weak var ratingView1: CosmosView!
    @IBOutlet weak var ratingAverageLabel1: UILabel!
    @IBOutlet weak var reviewCountLabel1: UILabel!
    @IBOutlet weak var firstReviewerView: UIView!
    @IBOutlet weak var firstReviewerName: UILabel!
    @IBOutlet weak var firstReviewerRatingView: CosmosView!
    @IBOutlet weak var firstReviewerReviewLabel: UILabel!
    @IBOutlet weak var readAllReviewsButton: UIButton!
    
    var averageRating: Double?
    var reviewCount: Int?
    var reviews: [Review] = []
    
    var selectedOptions: [String?] = []
    
    var variantAvailability: VariantAvailability = .AddToCart {
        didSet {
            if let addToCartButton = addToCartButton {
                switch variantAvailability {
                case .AddedToCart:
                    addToCartButton.setTitle("View in cart", for: .normal)
                case .AddToCart:
                    addToCartButton.setTitle("Add to cart", for: .normal)
                case .OutOfStock:
                    addToCartButton.setTitle("Out of stock", for: .normal)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        
        wishListContainerView.isHidden = false
        wishListContainerView.layer.cornerRadius = wishListContainerView.frame.width / 2
        wishListContainerView.layer.masksToBounds = true

        scrollView.isHidden = true
        
        configAddCartButton()
        descriptionWebView.scrollView.isScrollEnabled = false
        
        if !productID.isEmpty {
            SVProgressHUD.show()

            Client.shared.fetchProduct(id: productID) { model in
                SVProgressHUD.dismiss()

                self.scrollView.isHidden = false
                self.product = model
                self.updateProductUI()
            }
        }
        
        rateButton.layer.cornerRadius = 8
        rateButton.layer.borderColor = UIColor.gray.cgColor
        rateButton.layer.borderWidth = 1
        
        userImageView.layer.cornerRadius = userImageView.frame.width / 2
        
        fetchAverageRating()
        fetchInternalProductIdAndReviews()
//        fetchReviews()
        // Do any additional setup after loading the view.
    }
    
    func fetchAverageRating() {
        guard let id = Utils.extractProductID(from: productID) else { return }
        ReviewManager.shared.fetchAverageRating(productId: "\(id)") { averageRating, reviewCount, error in
            self.averageRating = averageRating
            self.reviewCount = reviewCount
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else if let averageRating = averageRating, let reviewCount = reviewCount {
                let formattedRating = String(format: "%.1f", averageRating)
                self.ratingView.rating = averageRating
                self.ratingAverageLabel.text = formattedRating+"/5"
                self.reviewCountLabel.text = "(\(reviewCount) Ratings)"
                
                self.ratingView1.rating = averageRating
                self.ratingAverageLabel1.text = formattedRating+"/5"
                self.reviewCountLabel1.text = "\(reviewCount) Ratings"
            }
        }
    }
    
    func fetchInternalProductIdAndReviews() {
        guard let id = Utils.extractProductID(from: productID) else { return }
        ReviewManager.shared.fetchInternalProductId(externalId: id) { productId, error in
            if let error = error {
                print("Error fetching internal product ID: \(error.localizedDescription)")
                return
            }
            self.judgeMeProductID = productId
            self.fetchReviews()
        }
    }
    
    func fetchReviews() {
        guard let id = judgeMeProductID else { return }
        let page = 1
        ReviewManager.shared.fetchReviews(productId: id, page: page) { reviews, error in
            if let error = error {
                print("Error fetching reviews: \(error.localizedDescription)")
                return
            }
            
            if let reviews = reviews, let firstReview = reviews.first {
                self.firstReviewerView.isHidden = false
                self.readAllReviewsButton.isHidden = false
                self.firstReviewerName.text = firstReview.reviewer.name
                self.firstReviewerRatingView.rating = Double(firstReview.rating)
                self.firstReviewerReviewLabel.text = firstReview.body
                self.reviews = reviews
            }
        }
    }
    
    func configAddCartButton() {
        addToCartButton.layer.cornerRadius = 8
        
        addToCartButton.layer.shadowColor = UIColor.gray.cgColor
        addToCartButton.layer.shadowRadius = 2
        addToCartButton.layer.shadowOpacity = 1
        addToCartButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        
        
    }
    
    func updateProductUI() {
        if let product = product {
            productImageUrls = product.images.items.map {
                $0.url.absoluteString
            }
            pageControl.numberOfPages = productImageUrls.count

            titleLabel.text = product.title
            
            var selectedVariantTitle = ""
            
            pageControl.isHidden = (productImageUrls.count <= 1)
            
            if !pageControl.isHidden {
                pageControl.currentPage = 0
            }
            
            if product.options.count == 1 {
                selectVariantLabel.isHidden = true
                optionsTableView.isHidden = true
                selectedOptions.insert(product.options[0].values.first, at: 0)
                selectedVariantTitle = selectedOptions.compactMap({$0}).first ?? ""
            } else {
                for i in 0..<product.options.count {
                    selectedOptions.insert(product.options[i].values.first, at: i)
                }
                selectedVariantTitle = selectedOptions.compactMap({$0}).joined(separator: " / ")
            }
            
            priceLabel.attributedText = product.variants.items.first?.formattedPriceString()
            
            if let availableForSale = product.variants.items.first?.availableForSale, !availableForSale {
                variantAvailability = .OutOfStock
            } else if CartManager.shared.isProductInCart(product: product, selectedVariantTitle: selectedVariantTitle) {
                variantAvailability = .AddedToCart
            } else {
                variantAvailability = .AddToCart
            }
            
            setupDescriptionWebView()
            
            pagerView.reloadData()
            optionsTableView.reloadData()
            
            if CartManager.shared.isProductInWishList(product: product) {
                wishListIcon.image = UIImage(systemName: "heart.fill")
            } else {
                wishListIcon.image = UIImage(systemName: "heart")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let product = product {
            var selectedVariantTitle = ""

            if product.options.count == 1 {
                selectedVariantTitle = selectedOptions.compactMap({$0}).first ?? ""
            } else {
                selectedVariantTitle = selectedOptions.compactMap({$0}).joined(separator: " / ")
            }
            
            if let selectedVariant = product.variants.items.filter({ $0.title == selectedVariantTitle }).first {
                if !selectedVariant.availableForSale {
                    variantAvailability = .OutOfStock
                } else if CartManager.shared.isProductInCart(product: product, selectedVariantTitle: selectedVariantTitle) {
                    variantAvailability = .AddedToCart
                } else {
                    variantAvailability = .AddToCart
                }
            }
        }
        
        rateTitleLabel.text = (AccountController.shared.accessToken == nil) ? "Login to Rate" : "Rate"
    }
    
    override func viewWillLayoutSubviews() {
        super.updateViewConstraints()
        self.optionsTableViewHeightConstraint?.constant = self.optionsTableView.intrinsicContentSize.height
    }
    
    func setupTableView() {
        optionsTableView.delegate = self
        optionsTableView.dataSource = self
        optionsTableView.register(UINib(nibName: "ProductVariantsTableViewCell", bundle: nil),
                                  forCellReuseIdentifier: "ProductVariantsTableViewCell")
    }
    
    func setupDescriptionWebView() {
        descriptionWebView.navigationDelegate = self
        let htmlString = product?.summary ?? ""
        let htmlStart = "<HTML><HEAD><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, shrink-to-fit=no\"><style>img{width:auto;height:auto;max-width:100%;}</style></HEAD><BODY>"
        let htmlEnd = "</BODY></HTML>"
        let htmlContent = "\(htmlStart)\(htmlString)\(htmlEnd)"
        
        let fontSetting = "<span style=\"font-family: -apple-system;font-size: 13\"</span>"

        descriptionWebView.loadHTMLString(fontSetting + htmlContent, baseURL: nil)
    }
    
    @IBAction func addToCartAction(_ sender: Any) {
        if variantAvailability == .AddedToCart {
            let productListViewController = storyboard?.instantiateViewController(withIdentifier: "CartViewController") as! CartViewController
            productListViewController.showMenu = false
            self.navigationController?.pushViewController(productListViewController, animated: true)
        } else {
            if let product = product {
                var selectedVariantTitle = ""
                if product.options.count == 1 {
                    selectedVariantTitle = selectedOptions.compactMap({$0}).first ?? ""
                } else {
                    selectedVariantTitle = selectedOptions.compactMap({$0}).joined(separator: " / ")
                }
                if let selectedVariant = product.variants.items.filter({ $0.title == selectedVariantTitle }).first {
                    if selectedVariant.availableForSale && !CartManager.shared.isProductInCart(product: product, selectedVariantTitle: selectedVariantTitle) {
                        variantAvailability = .AddedToCart

                        CartManager.shared.insertCartItem(product: product,
                                                          selectedVariantTitle: selectedVariantTitle,
                                                          selectedVariantAvailableQuantity: selectedVariant.availableQuantity,
                                                          selectedVariantID: selectedVariant.id,
                                                          productImageUrls: productImageUrls,
                                                          productPrice: selectedVariant.price,
                                                          compareAtPrice: selectedVariant.compareAtPrice ?? selectedVariant.price)
                    }
                }
            }
        }
    }
    
    @IBAction func wishListAction(_ sender: Any) {
        if let product = product {
            if CartManager.shared.isProductInWishList(product: product) {
                CartManager.shared.deleteWishListItem(product: product)
                wishListIcon.image = UIImage(systemName: "heart")
            } else {
                CartManager.shared.insertWishListItem(product: product)
                wishListIcon.image = UIImage(systemName: "heart.fill")
            }
        }
    }
    
    @IBAction func rateAction(_ sender: Any) {
        if (AccountController.shared.accessToken == nil) {
            let storyboard = UIStoryboard(name: "Account", bundle: nil)
            let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
            self.navigationController?.pushViewController(loginViewController, animated: true)
        } else {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "WriteReviewViewController") as! WriteReviewViewController
            vc.productID = productID
            vc.delegate = self
            vc.modalPresentationStyle = .overFullScreen // or .overCurrentContext
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    @IBAction func viewAllReviews(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "RatingandReviewViewController") as! RatingandReviewViewController
        vc.averageRating = averageRating
        vc.reviewCount = reviewCount
        vc.reviews = reviews
        vc.judgeMeProductID = judgeMeProductID
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension ProductDetailViewController: WriteReviewViewControllerDelegate {
    
    func didSubmitReview() {
        fetchAverageRating()
        fetchReviews()
    }
}

extension ProductDetailViewController: FSPagerViewDataSource, FSPagerViewDelegate {
    
    // MARK:- FSPagerViewDataSource
    
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return productImageUrls.count == 0 ? 1 : productImageUrls.count
    }
    
    public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
        if productImageUrls.count > 0 {
            cell.imageView?.contentMode = .scaleAspectFill
            if let url = URL(string: productImageUrls[index]) {
                cell.imageView?.kf.setImage(with: url)
            }
        } else {
            cell.imageView?.backgroundColor = .lightGray.withAlphaComponent(0.1)
            cell.imageView?.contentMode = .center
            cell.imageView?.image = UIImage(named: "no-image")!
        }
        return cell
    }
    
    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        pagerView.deselectItem(at: index, animated: true)
    }
    
    // MARK:- FSPagerViewDelegate
    
    func pagerViewWillEndDragging(_ pagerView: FSPagerView, targetIndex: Int) {
        self.pageControl.currentPage = targetIndex
    }
}

extension ProductDetailViewController: UITableViewDelegate, UITableViewDataSource {
  
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return product?.options.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductVariantsTableViewCell", for: indexPath) as! ProductVariantsTableViewCell
        cell.delegate = self
        if let options = product?.options {
            cell.setupUI(options: options[indexPath.row], selectedIndex: indexPath.row, selectedOption: selectedOptions[indexPath.row])
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

extension ProductDetailViewController: ProductVariantsTableViewCellDelegate {
    
    func updateSelectedOption(selectedIndex: Int?, selectedOption: String?) {
        if let selectedIndex = selectedIndex {
            selectedOptions[selectedIndex] = selectedOption
            let selectedVariantTitle = selectedOptions.compactMap({$0}).joined(separator: " / ")
            if let selectedVariant = product?.variants.items.filter({ $0.title == selectedVariantTitle }).first {
                priceLabel.attributedText = selectedVariant.formattedPriceString()
            }
            optionsTableView.reloadData()
            if let product = product {
                let selectedVariantTitle = selectedOptions.compactMap({$0}).joined(separator: " / ")
                if let selectedVariant = product.variants.items.filter({ $0.title == selectedVariantTitle }).first {
                    if !selectedVariant.availableForSale {
                        variantAvailability = .OutOfStock
                    } else if CartManager.shared.isProductInCart(product: product, selectedVariantTitle: selectedVariantTitle) {
                        variantAvailability = .AddedToCart
                    } else {
                        variantAvailability = .AddToCart
                    }
                }
            }
        }
    }
}

extension ProductDetailViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.readyState", completionHandler: { (complete, error) in
            if complete != nil {
                webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { (height, error) in
                    self.descriptionWebViewHeightConstraint.constant = height as? CGFloat ?? 100
                })
            }
        })
    }
}

final class DynamicSizeTableView: UITableView {
    override var contentSize:CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}
