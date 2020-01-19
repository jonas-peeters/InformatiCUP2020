//
//  UnitTests.swift
//  UnitTests
//
//  Created by Jonas Peeters on 01.01.20.
//

import XCTest

class UnitTests: XCTestCase {

    func testBasicNetworkCalculation() {
        let gpu = GPUEngine(1)
        let networkGPU = NeuralNetwork("testBasic", [1, 1], [
            Layer(1, 1, [1.2], [-1.0]),
        ])
        gpu.createBuffer([networkGPU], networkGPU.name)
        let inputGPU: [Float] = [2.0]
        let outputGPU = networkGPU.calculate(input: inputGPU, mutationNumber: 0, gpu)
        
        let cpu = CPUEngine(1)
        let networkCPU = NeuralNetwork("testBasic", [1, 1], [
            Layer(1, 1, [1.2], [-1.0]),
        ])
        cpu.createBuffer([networkCPU], networkCPU.name)
        let inputCPU: [Float] = [2.0]
        let outputCPU = networkCPU.calculate(input: inputCPU, mutationNumber: 0, cpu)
        
        XCTAssert(outputGPU[0].isApproximately(outputCPU[0]))
    }
    
    func testComplexNetworkCalculation() {
        let gpu = GPUEngine(1)
        let networkGPU = NeuralNetwork("testBasic", [3, 2], [
            Layer(2, 3, [2.0, 2.0, 4.0, -1.0, 3.0, -2.0], [1.0, -2.0]),
        ])
        gpu.createBuffer([networkGPU], networkGPU.name)
        let inputGPU: [Float] = [1.0, -1.0, 3.0]
        let outputGPU = networkGPU.calculate(input: inputGPU, mutationNumber: 0, gpu)
        
        let cpu = CPUEngine(1)
        let networkCPU = NeuralNetwork("testBasic", [3, 2], [
            Layer(2, 3, [2.0, 2.0, 4.0, -1.0, 3.0, -2.0], [1.0, -2.0]),
        ])
        cpu.createBuffer([networkCPU], networkCPU.name)
        let inputCPU: [Float] = [1.0, -1.0, 3.0]
        let outputCPU = networkCPU.calculate(input: inputCPU, mutationNumber: 0, cpu)
        
        XCTAssert(outputGPU[0].isApproximately(outputCPU[0]))
        XCTAssert(outputGPU[1].isApproximately(outputCPU[1]))
    }
    
    func testBasicNetworkMultiCalculation() {
        let gpu = GPUEngine(1)
        let networkGPU = NeuralNetwork("testBasic", [3, 1], [
            Layer(1, 3, [2.0, 1.0, 4.0], [1.0]),
        ])
        gpu.createBuffer([networkGPU], networkGPU.name)
        let input: [[Float]] = [[Float]](repeating: [1.0, -1.0, 3.0], count: 260).map {
            $0.map { _ in
                Float.random(in: -5...5)
            }
        }
        let outputGPU = networkGPU.calculate(input: input, mutationNumber: 0, gpu)
        
        let cpu = CPUEngine(1)
        let networkCPU = NeuralNetwork("testBasic", [3, 1], [
            Layer(1, 3, [2.0, 1.0, 4.0], [1.0]),
        ])
        cpu.createBuffer([networkCPU], networkCPU.name)
        let outputCPU = networkGPU.calculate(input: input, mutationNumber: 0, cpu)
        
        for i in 0..<input.count {
            XCTAssert(outputGPU[i][0].isApproximately(outputCPU[i][0]))
        }
    }
    
    func testComplexNetworkMultiCalculation() {
        let gpu = GPUEngine(1)
        let network = NeuralNetwork("testBasic", [3, 2], [
            Layer(2, 3, [2.0, 2.0, 4.0, -1.0, 3.0, -2.0], [1.0, -2.0]),
        ])
        gpu.createBuffer([network], network.name)
        let input: [[Float]] = [[Float]](repeating: [1.0, -1.0, 3.0], count: 260).map {
            $0.map { _ in
                Float.random(in: -5...5)
            }
        }
        let outputGPU = network.calculate(input: input, mutationNumber: 0, gpu)
        let cpu = CPUEngine(1)
        cpu.createBuffer([network], network.name)
        let outputCPU = network.calculate(input: input, mutationNumber: 0, cpu)
        for i in 0..<input.count {
            print(outputGPU[i][0])
            print(outputCPU[i][0])
            XCTAssert(outputGPU[i][0].isApproximately(outputCPU[i][0]))
            XCTAssert(outputGPU[i][1].isApproximately(outputCPU[i][1]))
        }
    }
    
    func testMutationPercentage() {
        let gpua = GPUEngine(1)
        for _ in 0..<100 {
            let inputArray = [Float](repeating: 1.0, count: 10000)
            let outputArray = gpua.mutate(arr: inputArray, multiplier: 1)
            
            var changed = 0
            var same = 0
            for i in 0..<inputArray.count {
                if inputArray[i].isApproximately(outputArray[i]) {
                    same += 1
                } else {
                    changed += 1
                }
            }
            XCTAssert(Double(changed) / Double(changed + same) < 0.05)
            XCTAssert(Double(changed) / Double(changed + same) > 0.01)
        }
        let cpue = CPUEngine(1)
        for _ in 0..<100 {
            let inputArray = [Float](repeating: 1.0, count: 10000)
            let outputArray = cpue.mutate(arr: inputArray, multiplier: 1)
            
            var changed = 0
            var same = 0
            for i in 0..<inputArray.count {
                if inputArray[i].isApproximately(outputArray[i]) {
                    same += 1
                } else {
                    changed += 1
                }
            }
            XCTAssert(Double(changed) / Double(changed + same) < 0.05)
            XCTAssert(Double(changed) / Double(changed + same) > 0.01)
        }
    }
    
    func testSaveLoad() {
        let gpua = GPUEngine(1)
        var nn = NeuralNetwork("testNetwork", [10, 5, 1], gpua)
        
        nn.saveToDisk()
        
        var loaded = NeuralNetwork("testNetwork", ifCantRead: [10, 5, 1], gpua)
        for i in 0..<loaded.layers.count {
            for j in 0..<loaded.layers[i].bias.count {
                XCTAssert(loaded.layers[i].bias[j] == nn.layers[i].bias[j])
            }
            for j in 0..<loaded.layers[i].weights.count {
                XCTAssert(loaded.layers[i].weights[j] == nn.layers[i].weights[j])
            }
        }
        
        loaded = loaded.mutateRandom(1, gpua)
        loaded.saveToDisk()
        
        nn = loaded
        loaded = NeuralNetwork("testNetwork", ifCantRead: [10, 5, 1], gpua)
        for i in 0..<loaded.layers.count {
            for j in 0..<loaded.layers[i].bias.count {
                XCTAssert(loaded.layers[i].bias[j] == nn.layers[i].bias[j])
            }
            for j in 0..<loaded.layers[i].weights.count {
                XCTAssert(loaded.layers[i].weights[j] == nn.layers[i].weights[j])
            }
        }
    }
}

extension Float {
    func isApproximately(_ f2: Float) -> Bool {
        return abs(self - f2) < abs(max(self, f2) / 1000)
    }
}
