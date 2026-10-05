//
//  APIError.swift
//  Generik API Client
//
//  Created by Sergey on 11/17/18.
//  Copyright © 2018 sblinov.com. All rights reserved.
//

import Foundation

enum APIError: Error {
    case cancelled
    case client
    case decoding(reason: [String: Any]?)
    case network(statusCode: Int, localizedDescription: String?)
    case noData
    case transport(error: Error)
    case unrecognizedFormat
}

extension APIError: LocalizedError {
    
    enum HttpStatusCode: Int {
        case notFound = 404
        case unhandled = -1
        
        init(statusCode: Int) {
            self = HttpStatusCode(rawValue: statusCode) ?? .unhandled
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .client:
            return NSLocalizedString("description-client-error", tableName: "APIError",
                                     value: "Oh no! Something went wrong creating the request to the server.",
                                     comment: "Error message for when the client encounters an error creating a request to the server.")
            
        case .network(let statusCode, let localizedDescription):
            guard localizedDescription == nil else { return localizedDescription }
            switch HttpStatusCode(statusCode: statusCode) {
            default: return nil
            }
            
        case .transport(let error):
            return error.localizedDescription
            
        default: return nil
        }
    }
    
}
