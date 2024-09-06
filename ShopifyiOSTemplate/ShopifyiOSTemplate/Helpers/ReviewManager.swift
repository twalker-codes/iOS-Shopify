//
//  ReviewManager.swift
//  ShopifyiOSTemplate
//
//  Created by mac on 20/07/24.
//

import Foundation
import Alamofire

struct ReviewsResponse: Decodable {
    let current_page: Int
    let per_page: Int
    let reviews: [Review]
}

struct Review: Identifiable, Decodable {
    var id: Int
    var rating: Int
    var body: String
    let reviewer: Reviewer
    var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case rating = "rating"
        case body = "body"
        case reviewer
        case createdAt = "created_at"
    }
}

struct Reviewer: Codable {
    let id, externalID: Int
    let email, name: String

    enum CodingKeys: String, CodingKey {
        case id
        case externalID = "external_id"
        case email, name
    }
}

struct SubmitReviewResponse: Decodable {
    let message: String
}

struct AverageRatingResponse: Decodable {
    let product_external_id: Int
    let badge: String
}

struct JudgeMeProductResponse: Decodable {
    let product: JudgeMeProduct
}

struct JudgeMeProduct: Decodable {
    let id: Int
}

class ReviewManager {
    static let shared = ReviewManager()
    private init() {}

    private let baseURL = "<shopify shop url here>"
    private let apiToken = "<shopify API token here>"
    private let shopDomain = "<shopify app domain name>"

    func submitReview(forProduct productId: Int, reviewerName: String, reviewerEmail: String, rating: Int, body: String, completion: @escaping (Result<SubmitReviewResponse, Error>) -> Void) {
        let urlString = "\(baseURL)"
        let parameters: [String: Any] = [
            "api_token": apiToken,
            "shop_domain": shopDomain,
            "platform": "shopify",
            "name": reviewerName,
            "email": reviewerEmail,
            "rating": rating,
            "body": body,
            "id": productId
        ]

        AF.request(urlString, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseDecodable(of: SubmitReviewResponse.self) { response in
            switch response.result {
            case .success(let review):
                completion(.success(review))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchAverageRating(productId: String, completion: @escaping (Double?, Int?, Error?) -> Void) {
        let urlString = "https://judge.me/api/v1/widgets/preview_badge?api_token=\(apiToken)&shop_domain=\(shopDomain)&external_id=\(productId)"
        
        AF.request(urlString).responseDecodable(of: AverageRatingResponse.self) { response in
            switch response.result {
            case .success(let judgeMeResponse):
                if let averageRating = self.extractAverageRating(from: judgeMeResponse.badge), let reviewCount = self.extractReviewCount(from: judgeMeResponse.badge) {
                    completion(averageRating, reviewCount, nil)
                } else {
                    completion(nil, nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse badge"]))
                }
            case .failure(let error):
                completion(nil, nil, error)
            }
        }
    }
    
    func fetchInternalProductId(externalId: Int, completion: @escaping (Int?, Error?) -> Void) {
        let urlString = "https://judge.me/api/v1/products/-1?api_token=\(apiToken)&shop_domain=\(shopDomain)&external_id=\(externalId)"
        
        AF.request(urlString).responseDecodable(of: JudgeMeProductResponse.self) { response in
            switch response.result {
            case .success(let productResponse):
                completion(productResponse.product.id, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    func fetchReviews(productId: Int, page: Int, completion: @escaping ([Review]?, Error?) -> Void) {
        let urlString = "https://judge.me/api/v1/reviews?api_token=\(apiToken)&shop_domain=\(shopDomain)&product_id=\(productId)&page=\(page)"
        
        AF.request(urlString).responseDecodable(of: ReviewsResponse.self) { response in
            switch response.result {
            case .success(let reviewsResponse):
                completion(reviewsResponse.reviews, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }

    func extractAverageRating(from badge: String) -> Double? {
        let regex = try? NSRegularExpression(pattern: "data-average-rating='(\\d+\\.\\d+)'", options: [])
        let nsString = badge as NSString
        let results = regex?.matches(in: badge, options: [], range: NSRange(location: 0, length: nsString.length))
        if let match = results?.first, let range = Range(match.range(at: 1), in: badge) {
            return Double(badge[range])
        }
        return nil
    }

    func extractReviewCount(from badge: String) -> Int? {
        let regex = try? NSRegularExpression(pattern: "data-number-of-reviews='(\\d+)'", options: [])
        let nsString = badge as NSString
        let results = regex?.matches(in: badge, options: [], range: NSRange(location: 0, length: nsString.length))
        if let match = results?.first, let range = Range(match.range(at: 1), in: badge) {
            return Int(badge[range])
        }
        return nil
    }
}
