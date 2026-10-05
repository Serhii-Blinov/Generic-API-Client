//
//  NetworkOperation.swift
//  Generik API Client
//
//  Created by Sergey on 11/17/18.
//  Copyright © 2018 sblinov.com. All rights reserved.
//

import Foundation

/// The completion is delivered on the main thread and is not called if the operation was cancelled.
class NetworkOperation<T:EndPoint>: AsynchronousOperation {
    private let completion: (APIResult<T>) -> Void
    private let client: APIClient
    private let endpoint: T
    
    private let taskLock = NSLock()
    private var task: URLSessionTask?
    
    init(client: APIClient, endpoint: T, completion: @escaping (APIResult<T>) -> Void) {
        self.completion = completion
        self.client = client
        self.endpoint = endpoint
        super.init()
    }
    
    override func main() {
        let task = client.sendRequest(for: endpoint) { result in
            let deliver = {
                guard !self.isCancelled else { return }
                self.completion(result)
            }
            Thread.isMainThread ? deliver() : DispatchQueue.main.async(execute: deliver)
            self.finish()
        }
        
        taskLock.lock()
        self.task = task
        taskLock.unlock()
        
        // cancel() may have been called before the task was stored.
        if isCancelled {
            task?.cancel()
        }
    }
    
    override func cancel() {
        super.cancel()
        
        taskLock.lock()
        let task = self.task
        taskLock.unlock()
        
        task?.cancel()
    }
}
