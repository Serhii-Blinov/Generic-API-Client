//
//  APIClient.swift
//  Generik API Client
//
//  Created by Sergey on 11/17/18.
//  Copyright © 2018 sblinov.com. All rights reserved.
//

import Foundation

enum APIResult<T: EndPoint> {
    case failure(error: APIError)
    case success(result: T.Response)
}

protocol APIClient {
    var baseUrlComponents: URLComponents { get }
    var session: URLSession { get }
    
    func buildRequest<T:EndPoint>(for resource: T) -> URLRequest?
    func buildUrl<T:EndPoint>(for resource: T) -> URL?
    func cancelAllTasks()
    @discardableResult
    func sendRequest<T:EndPoint>(for resource: T, completion: @escaping (APIResult<T>) -> Void) -> URLSessionTask?
}

extension APIClient {
    
    func buildRequest<T:EndPoint>(for resource: T) -> URLRequest? {
        guard let url = buildUrl(for: resource) else {
            // TODO: add log
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = resource.httpMethod.name
        request.httpBody = resource.httpBody
        
        resource.additionalHeaders?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
    
    func buildUrl<T:EndPoint>(for resource: T) -> URL? {
        guard
            let baseUrl = baseUrlComponents.url,
            var components = URLComponents(url: baseUrl, resolvingAgainstBaseURL: true)
            else {
                  // TODO: add log
                return nil
        }
        
        components.path = baseUrlComponents.path.appending(resource.path)
        components.queryItems = resource.queryItems
        
        return components.url
    }
    
    /// Cancels every task of `session`, so the client should own its session instead of using `URLSession.shared`.
    func cancelAllTasks() {
        session.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
    }
    
    @discardableResult
    func sendRequest<T:EndPoint>(for resource: T, completion: @escaping (APIResult<T>) -> Void) -> URLSessionTask? {
        guard let request = buildRequest(for: resource) else {
            completion(.failure(error: APIError.client))
            return nil
        }
        
        // TODO: add log
        
        let task = session.dataTask(with: request) { data, response, error in
            // TODO: add log
            
            let failWithError: (APIError) -> Void = { localizedError in
                // TODO: add log
                completion(.failure(error: localizedError))
            }
            
            if let error = error {
                if let urlError = error as? URLError, urlError.code == .cancelled {
                    failWithError(APIError.cancelled)
                } else {
                    failWithError(APIError.transport(error: error))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                failWithError(APIError.unrecognizedFormat)
                return
            }
            
            let statusCode = httpResponse.statusCode
            guard (200..<300).contains(statusCode) else {
                let localizedDescription = resource.localizedErrorDescription(forStatusCode: APIError.HttpStatusCode(statusCode: statusCode))
                failWithError(APIError.network(statusCode: statusCode, localizedDescription: localizedDescription))
                return
            }
            
            let data = data ?? Data()
            
            if data.isEmpty, let emptyResponse = EmptyResponse() as? T.Response {
                completion(.success(result: emptyResponse))
                return
            }
            
            guard !data.isEmpty else {
                failWithError(APIError.noData)
                return
            }
            
            do {
                completion(.success(result: try JSONDecoder().decode(T.Response.self, from: data)))
            } catch let error as NSError {
                failWithError(APIError.decoding(reason: error.userInfo))
            }
        }
        
        task.resume()
        return task
    }
}
