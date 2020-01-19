//
//  File.swift
//  InformatiCUP-2020
//
//  Created by Jonas Peeters on 15.01.20.
//

import Foundation

class CalculationEngine {    
    /// Number of clients running at the same time
    var threads: Int
    /// Semaphore for stopping predictions while the buffers are changed
    var sempahore: DispatchSemaphore
    
    init(_ threads: Int) {
        self.threads = threads
        sempahore = DispatchSemaphore(value: threads)
    }
    
    func random1D(length: Int) -> [Float] {
        preconditionFailure("This method must be overridden")
    }
    
    func calculate(mutation: Int, layer: Int, layerSize: Int, input: [Float], _ name: String) -> [Float] {
        preconditionFailure("This method must be overridden")
    }
    
    func calculate(mutation: Int, layer: Int, layerSize: Int, input: [[Float]], _ name: String) -> [[Float]] {
        preconditionFailure("This method must be overridden")
    }
    
    func plus(arr1: [Float], arr2: [Float]) -> [Float] {
        preconditionFailure("This method must be overridden")
    }
    
    func mutate(arr: [Float], multiplier: Float) -> [Float] {
        preconditionFailure("This method must be overridden")
    }
    
    func createBuffer(_ mutations: [NeuralNetwork], _ name: String) {
        preconditionFailure("This method must be overridden")
    }
}
