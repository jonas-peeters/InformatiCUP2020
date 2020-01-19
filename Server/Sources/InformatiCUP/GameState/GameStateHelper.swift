//
//  Helper.swift
//  InformatiCUP-2020
//
//  Created by Jonas Peeters on 17.01.20.
//

import Foundation

/// Convert the ++, +, o, -, -- notation into value from -2 to 2
/// - Parameter input: String that is `++`, `+`, `o`, `-` or `--`
func plusMinusToFloat(_ input: String) -> Float {
    switch input {
    case "++": return 2
    case "+": return 1
    case "o": return 0
    case "-": return -1
    case "--": return -2
    default: return 0
    }
}


extension Array where Element == Float {
    /// Get the index of the largest value in an array between two indices
    /// - Parameters:
    ///   - from: Start index for search
    ///   - to: End index for search
    func maxInSegment(from: Int, to: Int) -> Int {
        var max: Int = from
        for i in from..<to {
            if self[i] > self[max] {
                max = i
            }
        }
        return max
    }
    
    /// Get the index of the maximum value in an array
    func maxIndex() -> Int {
        var max: Int = 0
        for i in 0..<self.count {
            if self[i] > self[max] {
                max = i
            }
        }
        return max
    }
}
