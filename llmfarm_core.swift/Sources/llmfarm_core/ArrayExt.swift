//
//  ArrayExt.swift
//  Mia
//
//  Created by Byron Everson on 2/22/23.
//

import Accelerate

public extension Array {
    
    // Convenience unsafe mutable pointer - Apple's method is annoying
    var mutPtr: UnsafeMutablePointer<Element> {
        mutating get {
            self.withUnsafeMutableBufferPointer({$0}).baseAddress!
        }
    }
    
    // Split the array evenly into an array of arrays
    func split(_ count: Int) -> [[Element]] {
        var split: [[Element]] = []
        let splitCount = self.count / count
        for i in 0 ..< count {
            let start = i * splitCount
            let end = start + splitCount
            split.append(Array<Element>(self[start ..< end]))
        }
        return split
    }
    
}
