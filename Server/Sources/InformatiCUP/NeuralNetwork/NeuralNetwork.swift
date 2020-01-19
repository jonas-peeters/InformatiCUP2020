//
//  NeuralNetwork.swift
//  InformatiCUP
//
//  Created by Jonas Peeters on 27.12.19.
//

import Foundation

/// A neural network buildt from layers and nodes
class NeuralNetwork: NSObject, NSCoding {
    /// Name of the network (used for storage)
    var name: String
    /// Layers of this network
    var layers: [Layer]
    /// Sizes of the layers
    /// The first value is the number of inputs
    var layerSizes: [Int]
    /// Number of wins this network had in a generation
    var wins = 0
    /// Score of the network in a generation
    var score = 0
    /// How many scores were recorded
    var scoreCounter = 0
    
    /// Create a new neural network with random initlial values
    /// - Parameters:
    ///   - name: Name of the network
    ///   - layerSizes: Sizes of the layers. The first value is the number of inputs.
    ///   - engine: GPU accelerator fot generation random number
    init(_ name: String, _ layerSizes: [Int], _ engine: CalculationEngine) {
        self.name = name
        self.layerSizes = layerSizes
        layers = []
        for i in 1..<layerSizes.count {
            layers.append(Layer(layerSizes[i], layerSizes[i - 1], engine))
        }
    }
    
    /// Create a new neural network from premade layers
    /// - Parameters:
    ///   - name: Name of the network
    ///   - layerSizes: Sizes of the layers. The first value is the number of inputs.
    ///   - layers: Array of layers. The number of weights and biases must fit the layerSizes
    init(_ name: String, _ layerSizes: [Int], _ layers: [Layer]) {
        self.name = name
        self.layerSizes = layerSizes
        self.layers = layers
    }
    
    /// Read a neural network from the disk.
    ///
    /// If no network can be read, a new network with random values is generated from the parameters
    ///
    /// - Parameters:
    ///   - name: Name of the network
    ///   - layerSizes: Sizes of the layers. The first value is the number of inputs.
    ///   - engine: GPU accelerator fot generation random number
    init(_ name: String, ifCantRead layerSizes: [Int], _ engine: CalculationEngine) {
        if FileManager().fileExists(atPath: "\(FileManager.default.currentDirectoryPath)/networks/\(name)") {
            let nn = NSKeyedUnarchiver.unarchiveObject(withFile: "\(FileManager.default.currentDirectoryPath)/networks/\(name)") as! NeuralNetwork
            self.layers = nn.layers
            self.layerSizes = nn.layerSizes
            self.name = name
            print("Loaded network \(name)")
            super.init()
        } else {
            print("Initializing new base network \(name)")
            self.layerSizes = layerSizes
            self.name = name
            layers = []
            for i in 1..<layerSizes.count {
                layers.append(Layer(layerSizes[i], layerSizes[i - 1], engine))
            }
            super.init()
        }
    }
    
    /// Save th neural network to the current working directory
    func saveToDisk() {
        print("Writing \(name) to disk")
        let _ = NSKeyedArchiver.archiveRootObject(self, toFile: "\(FileManager.default.currentDirectoryPath)/networks/\(name)")
    }
    
    /// Calculate the result of a single input
    /// - Parameters:
    ///   - input: Input array of floats
    ///   - mutationNumber: Which mutation is this
    ///   - engine: GPU accelerator to speed up the calculation
    func calculate(input: [Float], mutationNumber: Int, _ engine: CalculationEngine) -> [Float] {
        var output = input
        for (i, layer) in layers.enumerated() {
            if layer.inputSize != output.count {
                fatalError("NN \(name) expected input size of \(layer.inputSize) but got \(output.count)")
            }
            output = engine.calculate(mutation: mutationNumber, layer: i, layerSize: layer.size, input: input, name)
        }
        return output
    }
    
    /// Calculate the result of multiple input
    /// - Parameters:
    ///   - input: Array of input array of floats
    ///   - mutationNumber: Which mutation is this
    ///   - engine: GPU accelerator to speed up the calculation
    func calculate(input: [[Float]], mutationNumber: Int, _ engine: CalculationEngine) -> [[Float]] {
        var output = input
        for (i, layer) in layers.enumerated() {
            output = engine.calculate(mutation: mutationNumber, layer: i, layerSize: layer.size, input: input, name)
        }
        return output
    }
    
    /// Create a new neural network by mutating the weights and biases of the layers
    /// - Parameters:
    ///   - rate: Learning rate
    ///   - engine: GPU accelerator to speed up mutation
    func mutateRandom(_ rate: Float, _ engine: CalculationEngine) -> NeuralNetwork {
        return NeuralNetwork(name, layerSizes, layers.map { layer in layer.mutateRandom(rate, engine)})
    }
    
    /// Helper class to encode the network
    /// - Parameter coder: An NSCoder
    func encode(with coder: NSCoder) {
        coder.encode(layers as Any, forKey: "layers")
        coder.encode(layerSizes as Any, forKey: "layerSizes")
    }
    
    /// Helper class to decode the network
    /// - Parameter coder: An NSCoder
    required init?(coder: NSCoder) {
        layerSizes = coder.decodeObject(forKey: "layerSizes") as! [Int]
        layers = coder.decodeObject(forKey: "layers") as! [Layer]
        name = ""
        super.init()
    }
}
