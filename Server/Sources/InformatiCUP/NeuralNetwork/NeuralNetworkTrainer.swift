//
//  NeuralNetworkTrainer.swift
//  InformatiCUP-2020
//
//  Created by Jonas Peeters on 17.01.20.
//

import Foundation

/// Class for training a neural network
class NeuralNetworkTrainer {
    /// The current main neural network
    var nn: NeuralNetwork
    /// The current mutations
    var mutations: [NeuralNetwork] = []
    /// How many rounds are played by a mutation in a generation
    var roundsPerMutation: Int
    /// GPU accelerator for calculations
    var engine: CalculationEngine
    /// How many predictions were made by this network
    var predictions = 0
    /// Score that was achieved by just sending EndRoundActions
    var baseScore = 0
    /// Sempaphore to disable the predictions while a new generation is being created
    var semaphore: DispatchSemaphore
    
    /// Create a new neural network trainer
    /// - Parameters:
    ///   - mutations: Number of mutations
    ///   - nn: Initial neural network
    ///   - engine: GPU accelerator for faster calculations
    ///   - roundsPerMutation: Amount of games played by a mutation in a generation
    init(_ mutations: Int, _ nn: NeuralNetwork, _ engine: CalculationEngine, _ roundsPerMutation: Int = 8) {
        self.nn = nn
        self.roundsPerMutation = roundsPerMutation
        self.engine = engine
        self.mutations.append(nn)
        semaphore = DispatchSemaphore(value: roundsPerMutation)
        
        for _ in 0..<mutations - 1 {
            self.mutations.append(NeuralNetwork(nn.name, nn.layerSizes, engine))
        }
        engine.createBuffer(self.mutations, nn.name)
    }
    
    /// Report a score for a mutation
    /// - Parameters:
    ///   - score: Number of points
    ///   - index: Score
    ///   - win: If the game was won
    func report(score: Int, for index: Int, _ win: Bool) {
        semaphore.wait()
        if index != mutations.count - 1 {
            mutations[index].score += score
            mutations[index].scoreCounter += 1
        } else {
            baseScore += score
        }
        if win {
            mutations[index].wins += 1
        }
        semaphore.signal()
    }
    
    /// Create the next generation
    ///
    /// This is done by looking at the scores of each mutations. The mutations with highest scores get the most slots of the next generation.
    /// Mutations if a score that is too low, are thrown out.
    ///
    /// - Parameter learningRate: Learning rate for the mutations
    func nextGeneration(_ learningRate: Float) {
        for _ in 0..<roundsPerMutation {
            semaphore.wait()
        }
        
        for nn in mutations {
            nn.score -= baseScore
        }
        
        var scoreString0 = "Pre sort scores are"
        for nn in mutations {
            scoreString0 += " \(nn.score) (\(nn.wins):\(roundsPerMutation - nn.wins)),"
        }
        scoreString0.removeLast()
        print(scoreString0)
        
        let mutationCountOfBest = Int(ceilf(Float(mutations.count) / Float(5)))
        var sum = 0
        var winSum = 0
        for i in 0..<mutationCountOfBest {
            sum += mutations[i].score
            winSum += mutations[i].wins
        }
        print("Average score of the last best network was \(sum / mutationCountOfBest) (\(winSum / mutationCountOfBest):\(roundsPerMutation - (winSum / mutationCountOfBest)))")
        
        
        let ranked = mutations.sorted(by: {
            $0.score > $1.score
        })
        
        var scoreString = "The scores are"
        for nn in ranked {
            scoreString += " \(nn.score) (\(nn.wins):\(roundsPerMutation - nn.wins)),"
        }
        scoreString.removeLast()
        print(scoreString)
        print("Doing nothing resulted in a score of \(baseScore)")
        
        ranked[0].saveToDisk()
        mutations = []
        
        print("Creating new mutations...")
        var n = 5
        for nn in ranked {
            for _ in 0..<Int(ceilf(Float(ranked.count) / Float(n))) {
                let new = nn.mutateRandom(learningRate, engine)
                new.score = 0
                new.scoreCounter = 0
                new.wins = 0
                mutations.append(new)
                if mutations.count >= ranked.count {
                    break
                }
            }
            n += 1
            if mutations.count >= ranked.count {
                break
            }
        }
        print("Created new mutations")
        baseScore = 0
        
        engine.createBuffer(mutations, nn.name)
        
        for _ in 0..<roundsPerMutation {
            semaphore.signal()
        }
    }
    
    /// Predict for a single input
    /// - Parameters:
    ///   - mutationIndex: Index of the mutation
    ///   - input: Input array of floats
    func predict(_ mutationIndex: Int, _ input: [Float]) -> [Float] {
        semaphore.wait()
        predictions += 1
        let r = mutations[mutationIndex].calculate(input: input, mutationNumber: mutationIndex, engine)
        semaphore.signal()
        return r
    }
    
    /// Predict for multiple inputs
    /// - Parameters:
    ///   - mutationIndex: Index of the mutation
    ///   - input: Input array of array of floats
    func predict(_ mutationIndex: Int, _ input: [[Float]]) -> [[Float]] {
        semaphore.wait()
        predictions += 1
        let r = mutations[mutationIndex].calculate(input: input, mutationNumber: mutationIndex, engine)
        semaphore.signal()
        return r
    }
}
