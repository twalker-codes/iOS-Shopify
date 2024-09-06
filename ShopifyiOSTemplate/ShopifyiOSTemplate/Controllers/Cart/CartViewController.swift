//
//  CartViewController.swift
//  ShopifyiOSTemplate
//
//  Created by Mac on 18/11/21.
//

import UIKit

struct CartModel {
    var productID: String
    var productPrice: Decimal
    var compareAtPrice: Decimal
    var productTitle: String
    var selectedQuantity: Int
    var availableQuantity: Int
    var productVariantTitle: String
    var productVariantID: String
    var productImageUrls: [String]
}

class CartViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var emptyStateView: UIView!
    var emptyStateVC: EmptyStateViewController?
    var checkout: CheckoutViewModel?
    var showMenu: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Cart"
        
        emptyStateVC?.emptyTitle = "Your Cart is Empty"
        emptyStateVC?.emptyMessage = "Looks like you haven't added anything to your cart yet"

        let cartModels = CartManager.shared.retrieveData()
        let totalPrice = cartModels.map({ $0.productPrice }).reduce(0, +)
        totalPriceLabel.text = Currency.stringFrom(totalPrice)

        setupTableView()
        
        if showMenu {
            self.navigationItem.leftBarButtonItems = [self.barButtonItem(image: UIImage(named: "hamburger")!.withRenderingMode(.alwaysTemplate), tag: 0, action: #selector(self.menuButtonAction(_:)))]
        }
    }
    
    @objc func menuButtonAction(_ button: UIButton){
        sideMenuController?.revealMenu()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        cartEmptyViewUpdate()
        checkCheckOutStatus()
    }
    
    func checkCheckOutStatus() {
        if let checkout = checkout {
            Client.shared.pollForReadyCheckout(checkout.id) { checkout in
                if checkout?.orderNumber != nil {
                    CartManager.shared.deleteAllCartItem()
                    self.cartEmptyViewUpdate()
                }
            }
        }
    }
    
    func cartEmptyViewUpdate() {
        tableView.reloadData()
        emptyStateView.isHidden = !CartManager.shared.retrieveData().isEmpty
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "CartTableViewCell", bundle: nil),
                                  forCellReuseIdentifier: "CartTableViewCell")
    }
    
    @IBAction func checkOutAction(_ sender: Any) {
        Client.shared.createCheckout(with: CartManager.shared.retrieveData()) { checkout in
            guard let checkout = checkout else {
                print("Failed to create checkout.")
                return
            }
            self.checkout = checkout
            let completeCreateCheckout: (CheckoutViewModel) -> Void = { checkout in
                self.openWKWebViewControllerFor(checkout.webURL, title: "Checkout")
            }
            
            completeCreateCheckout(checkout)
        }
    }
    
    func openWKWebViewControllerFor(_ url: URL, title: String) {
        let webController = WebViewController(url: url, accessToken: AccountController.shared.accessToken)
        webController.navigationItem.title = title
        self.navigationController?.pushViewController(webController, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "emptyStateSegue", let destinationVC = segue.destination as? EmptyStateViewController {
            self.emptyStateVC = destinationVC
        }
    }
}

extension CartViewController: UITableViewDelegate, UITableViewDataSource {
  
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CartManager.shared.retrieveData().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CartTableViewCell", for: indexPath) as! CartTableViewCell
        let cartModel = CartManager.shared.retrieveData()[indexPath.row]
        cell.setupUI(model: cartModel)
        cell.delegate = self
        return cell
    }
}

extension CartViewController: CartTableViewCellDelegate {
    
    func cartUpdated() {
        tableView.reloadData()
        let cartModels = CartManager.shared.retrieveData()
        let totalPrice = cartModels.map({ $0.productPrice * Decimal($0.selectedQuantity) }).reduce(0, +)
        totalPriceLabel.text = Currency.stringFrom(totalPrice)
        cartEmptyViewUpdate()
    }
    
    func cartVariantMaxReacher(availableQuantity: Int) {
        Utils.showAlertMessage(vc: self, title: "", message: "Maximum available quantity \(availableQuantity)")
    }
}
