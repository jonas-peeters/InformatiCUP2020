//
//  Layer.swift
//  InformatiCUP-2020
//
//  Created by Jonas Peeters on 17.01.20.
//

import Foundation

/// A layer of a neural network with weights and biases
class Layer: NSObject, NSCoding, Codable {
    /// Size of the layer
    var size: Int
    /// Amount of inputs
    var inputSize: Int
    /// Weights for this layer
    var weights: [Float]
    /// Biases for this layer
    var bias: [Float]
    
    /// Create a new layer with random values
    /// - Parameters:
    ///   - size: Size of the layer
    ///   - inputSize: Number of inputs
    ///   - engine: GPU accelerator to speed up generation
    init(_ size: Int, _ inputSize: Int, _ engine: CalculationEngine) {
        self.size = size
        self.inputSize = inputSize
        
        weights = engine.random1D(length: size * inputSize)
        bias = engine.random1D(length: size)
        super.init()
    }
    
    /// Create a new layer from premade weights and biases
    /// - Parameters:
    ///   - size: Size of the layer
    ///   - inputSize: Number of inputs
    ///   - weights: Weights
    ///   - bias: Biases
    init(_ size: Int, _ inputSize: Int, _ weights: [Float], _ bias: [Float]) {
        self.size = size
        self.inputSize = inputSize
        self.weights = weights
        self.bias = bias
        super.init()
    }
    
    /// Create a new layer from this layer by randomly mutating the weights and biases
    /// - Parameters:
    ///   - rate: Learning rate
    ///   - engine: GPU accelerator to speed up the mutation
    func mutateRandom(_ rate: Float, _ engine: CalculationEngine) -> Layer {
        return Layer(size, inputSize, engine.mutate(arr: weights, multiplier: rate), engine.mutate(arr: bias, multiplier: rate))
    }
    
    /// Helper for encoding the layer
    /// - Parameter coder: An NSCoder
    func encode(with coder: NSCoder) {
        coder.encode(size, forKey: "size")
        coder.encode(inputSize, forKey: "inputSize")
        coder.encode(weights as Any, forKey: "weights")
        coder.encode(bias as Any, forKey: "bias")
    }
    
    /// Helper for decoding a layer
    /// - Parameter coder: An NSCoder
    required init?(coder: NSCoder) {
        size = coder.decodeInteger(forKey: "size")
        inputSize = coder.decodeInteger(forKey: "inputSize")
        weights = coder.decodeObject(forKey: "weights") as! [Float]
        bias = coder.decodeObject(forKey: "bias") as! [Float]
        super.init()
    }
}
