//
//  WriteReviewViewController.swift
//  ShopifyiOSTemplate
//
//  Created by mac on 19/07/24.
//

import UIKit
import Cosmos

protocol WriteReviewViewControllerDelegate: AnyObject {
    func didSubmitReview()
}

class WriteReviewViewController: UIViewController {

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var ratingBar: CosmosView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    
    var productID = ""
    weak var delegate: WriteReviewViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backgroundView.layer.cornerRadius = 8
        
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.lightGray.cgColor
        
        textView.layer.cornerRadius = 5
        
        cancelButton.layer.cornerRadius = 5
        submitButton.layer.cornerRadius = 5
        
        ratingBar.settings.fillMode = .full
    }
    
    @IBAction func submitAction(_ sender: Any) {
        guard let id = Utils.extractProductID(from: productID) else { return }
        ReviewManager.shared.submitReview(forProduct: id,
                                          reviewerName: AccountController.shared.name ?? "",
                                          reviewerEmail: AccountController.shared.email ?? "",
                                          rating: Int(ratingBar.rating),
                                          body: textView.text ?? "") { result in
            switch result {
            case .success(let message):
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                    self.delegate?.didSubmitReview()
                }
            case .failure(let error):
                print("Failed to submit review: \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
