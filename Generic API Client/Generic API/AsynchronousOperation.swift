//
//  AsynchronousOperation.swift
//  Generik API Client
//
//  Created by Sergey on 11/17/18.
//  Copyright © 2018 sblinov.com. All rights reserved.
//

import Foundation

class AsynchronousOperation: Operation {
    
    enum State {
        case ready, executing, finished
        fileprivate var keyPath: String {
            switch self {
            case .ready: return "isReady"
            case .executing: return "isExecuting"
            case .finished: return "isFinished"
            }
        }
    }
    
    private let stateLock = NSLock()
    private var _state = State.ready
    
    private(set) var state: State {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return _state
        }
        set {
            let currentState = state
            // A finished operation must never leave the finished state.
            guard currentState != newValue, currentState != .finished else { return }
            
            willChangeValue(forKey: newValue.keyPath)
            willChangeValue(forKey: currentState.keyPath)
            stateLock.lock()
            _state = newValue
            stateLock.unlock()
            didChangeValue(forKey: currentState.keyPath)
            didChangeValue(forKey: newValue.keyPath)
        }
    }

    override var isReady: Bool {
        return super.isReady && state == .ready
    }
    
    override var isExecuting: Bool {
        return state == .executing
    }
    
    override var isFinished: Bool {
        return state == .finished
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override func start() {
        guard !isCancelled else {
            finish()
            return
        }
        
        state = .executing
        main()
    }
    
    /// Must be called by subclasses once their asynchronous work is done.
    func finish() {
        state = .finished
    }
}
