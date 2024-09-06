//
//  RatingandReviewViewController.swift
//  ShopifyiOSTemplate
//
//  Created by mac on 18/07/24.
//

import UIKit
import Cosmos

class RatingandReviewViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var rateButton: UIButton!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var ratingAverageLabel: UILabel!
    @IBOutlet weak var reviewCountLabel: UILabel!
    
    var judgeMeProductID: Int?
    var averageRating: Double?
    var reviewCount: Int?
    var reviews: [Review] = []
    
    var isLoadingData = false
    var isPageEnd = false
    var page = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        rateButton.layer.cornerRadius = 8
        rateButton.layer.borderColor = UIColor.gray.cgColor
        rateButton.layer.borderWidth = 1
        
        if let averageRating = averageRating, let reviewCount = reviewCount {
            let formattedRating = String(format: "%.1f", averageRating)
            self.ratingView.rating = averageRating
            self.ratingAverageLabel.text = formattedRating+"/5"
            self.reviewCountLabel.text = "\(reviewCount) Ratings"
        }
    }
    
    func loadMoreData() {
        isLoadingData = true
        
        guard let id = judgeMeProductID else { return }
        page += 1
        ReviewManager.shared.fetchReviews(productId: id, page: page) { reviews, error in
            self.isLoadingData = false
            if let error = error {
                print("Error fetching reviews: \(error.localizedDescription)")
                return
            }
            
            if let reviews = reviews {
                self.isPageEnd = reviews.isEmpty
                self.reviews.append(contentsOf: reviews)
                self.tableView.reloadData()
            }
        }
    }
}

extension RatingandReviewViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviews.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RatingandReviewTableViewCell", for: indexPath) as! RatingandReviewTableViewCell
        let review = reviews[indexPath.row]
        cell.nameLabel.text = review.reviewer.name
        cell.ratingView.rating = Double(review.rating)
        cell.reviewLabel.text = review.body
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (indexPath.row == reviews.count - 1), !isLoadingData, !isPageEnd {
            self.loadMoreData()
        }
    }
}

class RatingandReviewTableViewCell: UITableViewCell {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var reviewLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true
    }
}
