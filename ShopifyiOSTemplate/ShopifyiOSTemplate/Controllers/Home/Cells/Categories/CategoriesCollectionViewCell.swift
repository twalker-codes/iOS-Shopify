//
//  CategoriesCollectionViewCell.swift
//  ShopifyiOSTemplate
//
//  Created by Mac on 14/11/21.
//

import UIKit

class CategoriesCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var categoryImageView: UIImageView!
    @IBOutlet weak var categoryNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        categoryImageView.layer.masksToBounds = true
        categoryImageView.layer.cornerRadius = 30
    }

    func setupUI(model: CollectionViewModel?) {
        categoryImageView.image = nil
        categoryNameLabel.text = ""
        if let model = model {
            categoryImageView.kf.setImage(with: model.imageURL)
            categoryNameLabel.text = model.title
        }
    }
}
