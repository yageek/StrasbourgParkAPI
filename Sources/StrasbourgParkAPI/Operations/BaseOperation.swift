//
//  File.swift
//  
//
//  Created by eidd5180 on 01/07/2020.
//

import Foundation

open class BaseOperation: Operation {

    // MARK: - Helper Begin
    var _isFinished: Bool = false
    open override var isFinished: Bool {
        set {
            willChangeValue(forKey: "isFinished")
            _isFinished = newValue
            didChangeValue(forKey: "isFinished")
        }

        get {
            return _isFinished
        }
    }

    var _isExecuting: Bool = false

    open override var isExecuting: Bool {
        set {
            willChangeValue(forKey: "isExecuting")
            _isExecuting = newValue
            didChangeValue(forKey: "isExecuting")
        }

        get {
            return _isExecuting
        }
    }

    open func finish() {
        isExecuting = false
        isFinished = true
    }
}


