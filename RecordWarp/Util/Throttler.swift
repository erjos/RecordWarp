//
//  Throttler.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 11/9/19.
//  Copyright © 2019 Ethan Joseph. All rights reserved.
//

import Foundation

class Throttler {
    private let queue = DispatchQueue.global(qos: .background)
    private var job : DispatchWorkItem = DispatchWorkItem(block: {})
    private var previousRun: Date = Date.distantPast
    private var maxInterval: Double
    
    init(seconds: Double) {
        maxInterval = seconds
    }
    
    func throttle(block: @escaping ()->()) {
        job.cancel()
        job = DispatchWorkItem(block: {
            [weak self] in
            self?.previousRun = Date()
            block()
        })
        let secondsSinceRun = Date.second(from: previousRun)
        let delay =  secondsSinceRun > maxInterval ? 0 : (maxInterval - secondsSinceRun)
        queue.asyncAfter(deadline: .now() + Double(delay), execute: job)
    }
}

private extension Date {
    static func second(from referenceDate: Date) -> Double {
        return Double(Date().timeIntervalSince(referenceDate).rounded())
    }
}

