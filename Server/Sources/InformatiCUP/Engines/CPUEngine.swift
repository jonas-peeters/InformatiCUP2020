//
//  CPUEngine.swift
//  InformatiCUP-2020
//
//  Created by Jonas Peeters on 15.01.20.
//

import Foundation

class CPUEngine: CalculationEngine {
    private var buffers: [String : [Float]] = [:]
    private let e = Float(M_E)
    
    override func createBuffer(_ mutations: [NeuralNetwork], _ name: String) {
        for _ in 0..<threads {
            sempahore.wait()
        }
        for (i, nn) in mutations.enumerated() {
            for (j, layer) in nn.layers.enumerated() {
                buffers["\(name), \(i), \(j), 0"] = layer.weights
                buffers["\(name), \(i), \(j), 1"] = layer.bias
            }
        }
        for _ in 0..<threads {
            sempahore.signal()
        }
    }
    
    override func random1D(length: Int) -> [Float] {
        return [Float](repeating: 0, count: length).map { _ in
            Float.random(in: -1...1)
        }
    }
    
    override func calculate(mutation: Int, layer: Int, layerSize: Int, input: [Float], _ name: String) -> [Float] {
        let weights = buffers["\(name), \(mutation), \(layer), 0"]!
        let bias = buffers["\(name), \(mutation), \(layer), 1"]!
        
        return [Int](0..<layerSize).map { index in
            var sum = bias[index]
            for i in 0..<weights.count / layerSize {
                sum += weights[index + i * layerSize] * input[i]
            }
            return sigmoid(sum)
        }
    }
    
    override func calculate(mutation: Int, layer: Int, layerSize: Int, input: [[Float]], _ name: String) -> [[Float]] {
        let weights = buffers["\(name), \(mutation), \(layer), 0"]!
        let bias = buffers["\(name), \(mutation), \(layer), 1"]!
        
        return input.map { floats in
            return [Int](0..<layerSize).map { index in
                var sum = bias[index]
                for i in 0..<weights.count / layerSize {
                    sum += weights[index + i * layerSize] * floats[i]
                }
                return sigmoid(sum)
            }
        }
    }
    
    override func plus(arr1: [Float], arr2: [Float]) -> [Float] {
        return [Int](0..<arr1.count).map { i in
            arr1[i] + arr2[i]
        }
    }
    
    override func mutate(arr: [Float], multiplier: Float) -> [Float] {
        return arr.map { value in
            if (Float.random(in: 0...1) > 0.97) {
                return value + Float.random(in: 0...1) * multiplier * multiplier - multiplier * multiplier / 2
            } else {
                return value
            }
        }
    }
    
    private func sigmoid(_ x: Float) -> Float {
        return 1 / (1.0 + pow(e, -x));
    }
}
