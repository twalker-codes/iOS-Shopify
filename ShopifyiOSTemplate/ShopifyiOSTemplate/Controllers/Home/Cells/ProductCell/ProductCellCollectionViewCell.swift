//
//  ProductCellCollectionViewCell.swift
//  ShopifyiOSTemplate
//
//  Created by Mac on 13/11/21.
//

import UIKit
import Kingfisher
import Cosmos

class ProductCellCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var wishListContainerView: UIView!
    @IBOutlet weak var wishListIcon: UIImageView!
    @IBOutlet weak var ratingContainerView: UIView!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var averageRatingLabel: UILabel!
    @IBOutlet weak var reviewsCountLabel: UILabel!
    var product: ProductViewModel?
    var wishListItem: WishListModel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setupUI(model: ProductViewModel?, rating: String, reviewCount: Int, showWishList: Bool = false) {
        self.product = model
        self.productImageView.image = nil
        self.titleLabel.text = ""
        self.priceLabel.attributedText = nil

        if rating.isEmpty {
            ratingView.rating = 0
        } else {
            ratingView.rating = Double(rating) ?? 0
        }
        
        reviewsCountLabel.text = "(\(reviewCount))"
        
        if showWishList {
            wishListContainerView.isHidden = false
            wishListContainerView.layer.cornerRadius = wishListContainerView.frame.width / 2
            wishListContainerView.layer.masksToBounds = true
            
            if let product = product {
                if CartManager.shared.isProductInWishList(product: product) {
                    wishListIcon.image = UIImage(systemName: "heart.fill")
                } else {
                    wishListIcon.image = UIImage(systemName: "heart")
                }
            }
        } else {
            wishListContainerView.isHidden = true
        }
        
        if let model = model {
            self.titleLabel.text = model.title
            self.priceLabel.text = model.price
            self.priceLabel.attributedText = model.variants.items.first?.formattedPriceString()

            if model.images.items.count > 0 {
                self.productImageView.contentMode = .scaleAspectFill
                self.productImageView.kf.setImage(with: model.images.items.first?.url)
            } else {
                self.productImageView.backgroundColor = .lightGray.withAlphaComponent(0.1)
                self.productImageView.contentMode = .center
                self.productImageView.image = UIImage(named: "no-image")!
            }
            
        }
    }
    
    func setupUI(model: WishListModel?, showWishList: Bool = false) {
        self.wishListItem = model
        self.productImageView.image = nil
        self.titleLabel.text = ""
        self.priceLabel.isHidden = true

        if showWishList {
            wishListContainerView.isHidden = false
            wishListContainerView.layer.cornerRadius = wishListContainerView.frame.width / 2
            wishListContainerView.layer.masksToBounds = true
            
            if let product = product {
                if CartManager.shared.isProductInWishList(product: product) {
                    wishListIcon.image = UIImage(systemName: "heart.fill")
                } else {
                    wishListIcon.image = UIImage(systemName: "heart")
                }
            }
        } else {
            wishListContainerView.isHidden = true
        }
        
        if let model = model {
            self.titleLabel.text = model.productTitle
            if let urlString = model.productImageUrls.first {
                self.productImageView.kf.setImage(with: URL(string: urlString))
            } else {
                self.productImageView.backgroundColor = .lightGray.withAlphaComponent(0.1)
                self.productImageView.contentMode = .center
                self.productImageView.image = UIImage(named: "no-image")!
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
    
}
