//
//  Endpoint.swift
//  Generik API Client
//
//  Created by Sergey on 11/17/18.
//  Copyright © 2018 sblinov.com. All rights reserved.
//

import Foundation

/// Use as `Response` for endpoints that return no body (e.g. 204 No Content).
struct EmptyResponse: Codable {}

protocol EndPoint {
    associatedtype Response: Decodable
    
    var additionalHeaders: [String: String]? { get }
    var httpBody: Data? { get }
    var httpMethod: HTTPMethod { get }
    var path: String { get }
    var queryItems: [URLQueryItem]? { get }
    
    func localizedErrorDescription(forStatusCode statusCode: APIError.HttpStatusCode) -> String?
}

extension EndPoint {
    var additionalHeaders: [String: String]? {
        return nil
    }
    
    var httpBody: Data? {
        return nil
    }
    
    var queryItems: [URLQueryItem]? {
        return nil
    }
    
    func localizedErrorDescription(forStatusCode statusCode: APIError.HttpStatusCode) -> String? {
        return nil
    }
}
