//
//  GPUAccelerator.swift
//  InformatiCUP
//
//  Created by Jonas Peeters on 27.12.19.
//


import Foundation

#if canImport(MetalKit)
import MetalKit

/// Class for accelerating specific calculations and array operations using the GPU
///
/// This only works on macOS 10.15 and higher
@available(OSX 10.13, *)
class GPUEngine: CalculationEngine {
    /// Representation of the physical GPU device
    var device: MTLDevice
    /// Queue for GPU commands
    private var commandQueue: MTLCommandQueue
    /// Library of available GPU functions, default to all device methods in .metal files that belong to the project
    private var defaultLibrary: MTLLibrary!
    /// Shader for generating random numbers
    private var randomShader: MTLFunction
    /// State of the pipeline for the random shader
    private var randomPipelineState: MTLComputePipelineState
    /// Shader for the network predictions
    private var calculateShader: MTLFunction
    /// State of the pipeline for the calculationg shader
    private var calculatePipelineState: MTLComputePipelineState
    /// Shader for multi network predictions
    private var calculateMultiShader: MTLFunction
    /// State of the pipeline for the multi calculationg shader
    private var calculateMultiPipelineState: MTLComputePipelineState
    /// Shader for adding all values for two arrays
    private var plusShader: MTLFunction
    /// State of the pipeline for the plus shader
    private var plusPipelineState: MTLComputePipelineState
    /// Shader for mutating a layer
    private var mutateShader: MTLFunction
    /// State of the pipeline for the mutation shader
    private var mutatePipelineState: MTLComputePipelineState
    /// Buffers for the weights and biases of all current networks
    private var buffers: [String : MTLBuffer] = [:]
    
    /// Create a new GPU accelerator
    /// - Parameter threads: Number of parallel active clients
    override init(_ threads: Int) {
        let devicesWithObserver = MTLCopyAllDevicesWithObserver(handler: {_,_ in })
        let deviceList = devicesWithObserver.devices
        
        device = MTLCreateSystemDefaultDevice()!
        
        for d in deviceList {
            if !d.isLowPower {
                device = d
            }
        }
        
        print("Selecting \(device.name) for GPU acceleration")
        
        commandQueue = device.makeCommandQueue()!
        do {
            if let dL = device.makeDefaultLibrary() {
                defaultLibrary = dL
            } else {
                defaultLibrary = try device.makeLibrary(filepath: "/Users/peeters/Documents/Developement/informatiCUP-2020/swift_trainer_2/UnitTests/GPUFunctions.metallib")
            }
            randomShader = defaultLibrary.makeFunction(name: "random")!
            calculateShader = defaultLibrary.makeFunction(name: "calculate")!
            calculateMultiShader = defaultLibrary.makeFunction(name: "calculateMulti")!
            plusShader = defaultLibrary.makeFunction(name: "plus")!
            mutateShader = defaultLibrary.makeFunction(name: "mutate")!
            
            randomPipelineState = try device.makeComputePipelineState(function: randomShader)
            calculatePipelineState = try device.makeComputePipelineState(function: calculateShader)
            plusPipelineState = try device.makeComputePipelineState(function: plusShader)
            mutatePipelineState = try device.makeComputePipelineState(function: mutateShader)
            calculateMultiPipelineState = try device.makeComputePipelineState(function: calculateMultiShader)
        } catch {
            fatalError()
        }
        super.init(threads)
    }
    
    /// Create GPU buffers for all mutations of a neural network
    /// - Parameters:
    ///   - mutations: List of neural networks
    ///   - name: Name of the networks
    override func createBuffer(_ mutations: [NeuralNetwork], _ name: String) {
        for _ in 0..<threads {
            sempahore.wait()
        }
        print("Initializing GPU buffers...")
        for (i, nn) in mutations.enumerated() {
            for (j, layer) in nn.layers.enumerated() {
                if let mtlBuffer = buffers["\(name), \(i), \(j), 0"] {
                    mtlBuffer.setPurgeableState(.empty)
                }
                buffers["\(name), \(i), \(j), 0"] = nil
                buffers["\(name), \(i), \(j), 0"] = device.makeBuffer(bytes: layer.weights, length: layer.weights.count * MemoryLayout<Float>.stride, options: .cpuCacheModeWriteCombined)
                if let mtlBuffer = buffers["\(name), \(i), \(j), 1"] {
                    mtlBuffer.setPurgeableState(.empty)
                }
                buffers["\(name), \(i), \(j), 1"] = nil
                buffers["\(name), \(i), \(j), 1"] = device.makeBuffer(bytes: layer.bias, length: layer.bias.count * MemoryLayout<Float>.stride, options: .cpuCacheModeWriteCombined)
            }
        }
        print("Initialized GPU buffers")
        for _ in 0..<threads {
            sempahore.signal()
        }
    }
    
    /// Create a new 1D array of random numbers
    /// - Parameter length: Desired length of the array
    override func random1D(length: Int) -> [Float] {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        let outBuffer = device.makeBuffer(length: length * MemoryLayout<Float>.stride, options: .storageModeShared)
        let randomsBuffer = device.makeBuffer(bytes: [Int32.random(in: 0...10000), Int32.random(in: 0...10000), Int32.random(in: 0...10000)], length: 3 * MemoryLayout<Int32>.stride, options: [])
        
        computeCommandEncoder.setBuffer(outBuffer, offset: 0, index: 0)
        computeCommandEncoder.setBuffer(randomsBuffer, offset: 0, index: 1)
        computeCommandEncoder.setComputePipelineState(randomPipelineState)
        
        let threadExecutionWidth = randomPipelineState.threadExecutionWidth
        let threadsPerGroup = MTLSize(width: threadExecutionWidth, height: 1, depth: 1)
        let numThreadgroups = MTLSize(width: (length + threadExecutionWidth) / threadExecutionWidth, height: 1, depth: 1)
        computeCommandEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
        computeCommandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        let result = outBuffer!.contents().bindMemory(to: Float.self, capacity: length)
        let data = Array(UnsafeBufferPointer(start: result, count: length))
        return data
    }
    
    /// Calculate the output of a layer with a given input
    /// - Parameters:
    ///   - mutation: Index of the mutation in the generation
    ///   - layer: Index of the layer in the network
    ///   - layerSize: Size of the layer
    ///   - input: Input array of floats
    ///   - name: Name of the network for accessing buffers
    override func calculate(mutation: Int, layer: Int, layerSize: Int, input: [Float], _ name: String) -> [Float] {
        sempahore.wait()
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        let outBuffer = device.makeBuffer(length: layerSize * MemoryLayout<Float>.stride, options: .storageModeShared)
        
        computeCommandEncoder.setBuffer(buffers["\(name), \(mutation), \(layer), 0"], offset: 0, index: 0)
        computeCommandEncoder.setBuffer(buffers["\(name), \(mutation), \(layer), 1"], offset: 0, index: 1)
        computeCommandEncoder.setBytes(UnsafeRawPointer(input), length: input.count * MemoryLayout<Float>.stride, index: 2)
        let args: [Int32] = [Int32(layerSize), Int32(input.count)]
        computeCommandEncoder.setBytes(UnsafeRawPointer(args), length: args.count * MemoryLayout<Int32>.stride, index: 3)
        computeCommandEncoder.setBuffer(outBuffer, offset: 0, index: 4)
        computeCommandEncoder.setComputePipelineState(calculatePipelineState)
        
        let threadExecutionWidth = calculatePipelineState.threadExecutionWidth
        let threadsPerGroup = MTLSize(width: threadExecutionWidth, height: 1, depth: 1)
        let numThreadgroups = MTLSize(width: (layerSize + threadExecutionWidth) / threadExecutionWidth, height: 1, depth: 1)
        computeCommandEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
        computeCommandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        sempahore.signal()
        let result = outBuffer!.contents().bindMemory(to: Float.self, capacity: layerSize)
        let data = Array(UnsafeBufferPointer(start: result, count: layerSize))
        return data
    }
    
    override func calculate(mutation: Int, layer: Int, layerSize: Int, input: [[Float]], _ name: String) -> [[Float]] {
        sempahore.wait()
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        var inputArray: [Float] = []
        inputArray.reserveCapacity(input.count * input[0].count)
        for i in input {
            inputArray.append(contentsOf: i)
        }
        
        let inputBuffer = device.makeBuffer(bytes: inputArray, length: inputArray.count * MemoryLayout<Float>.stride, options: [])
        let outBuffer = device.makeBuffer(length: layerSize * input.count * MemoryLayout<Float>.stride, options: .storageModeShared)
                    
        computeCommandEncoder.setBuffer(buffers["\(name), \(mutation), \(layer), 0"], offset: 0, index: 0)
        computeCommandEncoder.setBuffer(buffers["\(name), \(mutation), \(layer), 1"], offset: 0, index: 1)
        computeCommandEncoder.setBuffer(inputBuffer, offset: 0, index: 2)
        let args: [Int32] = [Int32(layerSize), Int32(input[0].count)]
        computeCommandEncoder.setBytes(UnsafeRawPointer(args), length: args.count * MemoryLayout<Int32>.stride, index: 3)
        computeCommandEncoder.setBuffer(outBuffer, offset: 0, index: 4)
        computeCommandEncoder.setComputePipelineState(calculateMultiPipelineState)
        
        let threadExecutionWidth = calculateMultiPipelineState.threadExecutionWidth
        let threadsPerGroup = MTLSize(width: threadExecutionWidth, height: 1, depth: 1)
        let numThreadgroups = MTLSize(width: (layerSize * input.count + threadExecutionWidth) / threadExecutionWidth, height: 1, depth: 1)
        computeCommandEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
        computeCommandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        sempahore.signal()
        let result = outBuffer!.contents().bindMemory(to: Float.self, capacity: layerSize * input.count)
        let data = Array(UnsafeBufferPointer(start: result, count: layerSize * input.count))
        var out: [[Float]] = []
        out.reserveCapacity(input.count)
        for i in 0..<input.count {
            out.append(Array(data[i * layerSize..<(i + 1) * layerSize]))
        }
        return out
    }
    
    override func plus(arr1: [Float], arr2: [Float]) -> [Float] {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        let length = arr1.count
        let arr1Buffer = device.makeBuffer(bytes: arr1, length: length * MemoryLayout<Float>.stride, options: [])
        let arr2Buffer = device.makeBuffer(bytes: arr2, length: length * MemoryLayout<Float>.stride, options: [])
        let outBuffer = device.makeBuffer(length: length * MemoryLayout<Float>.stride, options: .storageModeShared)
        
        computeCommandEncoder.setBuffer(arr1Buffer, offset: 0, index: 0)
        computeCommandEncoder.setBuffer(arr2Buffer, offset: 0, index: 1)
        computeCommandEncoder.setBuffer(outBuffer, offset: 0, index: 2)
        computeCommandEncoder.setComputePipelineState(plusPipelineState)
        
        let threadExecutionWidth = plusPipelineState.threadExecutionWidth
        let threadsPerGroup = MTLSize(width: threadExecutionWidth, height: 1, depth: 1)
        let numThreadgroups = MTLSize(width: (length + threadExecutionWidth) / threadExecutionWidth, height: 1, depth: 1)
        computeCommandEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
        computeCommandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        let result = outBuffer!.contents().bindMemory(to: Float.self, capacity: length)
        let data = Array(UnsafeBufferPointer(start: result, count: length))
        return data
    }
    
    override func mutate(arr: [Float], multiplier: Float) -> [Float] {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        let length = arr.count
        let args = [multiplier, Float.random(in: 0...100), Float.random(in: 0...100), Float.random(in: 0...100)]
        let mult = device.makeBuffer(bytes: args, length: args.count * MemoryLayout<Float>.stride, options: [])
        let arrBuffer = device.makeBuffer(bytes: arr, length: length * MemoryLayout<Float>.stride, options: [])
        let outBuffer = device.makeBuffer(length: length * MemoryLayout<Float>.stride, options: .storageModeShared)
        
        computeCommandEncoder.setBuffer(mult, offset: 0, index: 0)
        computeCommandEncoder.setBuffer(arrBuffer, offset: 0, index: 1)
        computeCommandEncoder.setBuffer(outBuffer, offset: 0, index: 2)
        computeCommandEncoder.setComputePipelineState(mutatePipelineState)
        
        let threadExecutionWidth = mutatePipelineState.threadExecutionWidth
        let threadsPerGroup = MTLSize(width: threadExecutionWidth, height: 1, depth: 1)
        let numThreadgroups = MTLSize(width: (length + threadExecutionWidth) / threadExecutionWidth, height: 1, depth: 1)
        computeCommandEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
        computeCommandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        let result = outBuffer!.contents().bindMemory(to: Float.self, capacity: length)
        let data = Array(UnsafeBufferPointer(start: result, count: length))
        return data
    }
}
#endif
