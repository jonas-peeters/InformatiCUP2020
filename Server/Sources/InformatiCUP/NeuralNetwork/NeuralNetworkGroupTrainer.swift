//
//  NeuralNetworkGroupTrainer.swift
//  InformatiCUP-2020
//
//  Created by Jonas Peeters on 17.01.20.
//

import Foundation

/// Class for training multiple neural networks at the same time
class NeuralNetworkGroupTrainer {
    /// List of individual neural network trainers
    var trainers: [NeuralNetworkTrainer] = []
    /// How many rounds have been finished
    var finished = 0
    /// Amount of different mutations per generations
    var mutations: Int
    /// Number of rounds each mutations runs in a single generation
    var roundsPerMutation: Int
    /// How many rounds have been started
    var started = 0
    /// How many rounds are currently running
    var running = 0
    /// The number of predictions made
    /// This number can be reset by a third party function for statistics over time
    var predictions = 0
    /// If the training is currently blocked due to e.g. the next generation being prepared
    var blocked = true
    /// Score when doing nothing
    var baseScore = 0
    /// Number of wins
    var wins = 0
    /// Sum of all scores
    var scoreSum = 0
    /// Sum of the scores of the previous generation
    var previousScoreSum = 0
    /// The current learning rate
    var learningRate: Float
    /// Semaphore to stop multiple threads from stating more client at the same time
    var clientStarter = DispatchSemaphore(value: 1)
    
    /// Create a new training group
    /// - Parameters:
    ///   - neuralNetworks: Array of neural networks to train
    ///   - mutations: NUmber of mutations per generation
    ///   - roundsPerMutation: Number of rounds each mutation runs in a generation
    ///   - learningRate: Starting learning rate
    ///   - engine: A GPU accelerator for faster array operations
    init(_ neuralNetworks: [NeuralNetwork],
         _ mutations: Int,
         _ roundsPerMutation: Int,
         _ learningRate: Float,
         _ engine: CalculationEngine) {
        self.mutations = mutations
        self.roundsPerMutation = roundsPerMutation
        self.learningRate = learningRate
        
        for nn in neuralNetworks {
            trainers.append(NeuralNetworkTrainer(mutations, nn, engine, roundsPerMutation))
        }
        blocked = false
    }
    
    /// Predict for a single input
    /// - Parameters:
    ///   - name: Name of the neural network to use for the prediction
    ///   - mutation: Index of the mutation
    ///   - input: Input array of floats
    func predict(_ name: String, _ mutation: Int, _ input: [Float]) -> [Float] {
        if !blocked {
            predictions += 1
            for trainer in trainers {
                if trainer.nn.name == name {
                    return trainer.predict(mutation, input)
                }
            }
        }
        return []
    }
    
    /// Predict for multiple inputs
    /// - Parameters:
    ///   - name: Name of the neural network to use for the prediction
    ///   - mutation: Index of the mutation
    ///   - input: Array of input arrays of floats
    func predict(_ name: String, _ mutation: Int, _ input: [[Float]]) -> [[Float]] {
        if !blocked {
            predictions += 1
            for trainer in trainers {
                if trainer.nn.name == name {
                    return trainer.predict(mutation, input)
                }
            }
        }
        return []
    }
    
    /// Save the score for a specific mutation
    /// - Parameters:
    ///   - score: Number of points
    ///   - mutation: Which mutation should get the points
    ///   - win: If the game was won
    func report(_ score: Int, _ mutation: Int, _ win: Bool) {
        for trainer in trainers {
            trainer.report(score: score, for: mutation, win)
        }
        if win {
            wins += 1
        }
        if mutation != mutations - 1 {
            scoreSum += score
        } else {
            baseScore += score
        }
    }
    
    /// Tell each network trainer to move on to the next generation
    func nextGeneration() {
        blocked = true
        print("Next generation:")
        print("The score was \(scoreSum) with an average of \(Float(scoreSum) / Float((mutations - 1) * roundsPerMutation)).")
        print("The score doing nothing was \(baseScore * (mutations - 1)) with an average of \(Float(baseScore) / Float(roundsPerMutation)).")
        print("The cleaned score was \(scoreSum - baseScore * (mutations - 1)) with an average of \(Float(scoreSum - baseScore * (mutations - 1)) / Float((mutations - 1) * roundsPerMutation)).")
        if scoreSum - baseScore * (mutations - 1) < previousScoreSum && learningRate < 1 {
            learningRate /= 0.95
        } else if scoreSum - baseScore * (mutations - 1) > previousScoreSum {
            learningRate *= 0.95
        }
        previousScoreSum = scoreSum - baseScore * (mutations - 1)
        scoreSum = 0
        baseScore = 0
        for trainer in trainers {
            trainer.nextGeneration(learningRate)
        }
        running = 0
        started = 0
        finished = 0
        startClients()
    }
    
    /// Start new clients
    ///
    /// This method will automatically call itself when clients finish to start new ones, until the total amount of clients were started
    func startClients() {
        clientStarter.wait()
        blocked = false
        if self.running >= PARALLEL_CLIENTS {
            clientStarter.signal()
            return
        }
        if mode == .training {
            running += mutations
            started += mutations
            let seed = Int(Date().timeIntervalSince1970) * 100 + Int.random(in: 0..<100)
            for i in 0..<mutations {
                let process = Process()
                if #available(OSX 10.13, *) {
                    process.executableURL = URL(fileURLWithPath: clientPath).absoluteURL
                } else {
                    process.launchPath = URL(fileURLWithPath: clientPath).absoluteString
                }
                process.arguments = ["-u", "http://localhost:\(50123 + i)", "-t", "3000000", "--random-seed", "\(seed)"]
                process.standardOutput = FileHandle(forWritingAtPath: "/dev/null")
                process.terminationHandler = { process in
                    self.finished += 1
                    self.running -= 1
                    if self.finished >= self.mutations * self.roundsPerMutation {
                        self.nextGeneration()
                    } else {
                        while self.running < PARALLEL_CLIENTS && self.started < self.mutations * self.roundsPerMutation {
                            self.startClients()
                        }
                    }
                }
                do {
                    if #available(OSX 10.13, *) {
                        try process.run()
                    } else {
                        process.launch()
                    }
                } catch {
                    fatalError("Could not launch client! Aborting! Is the path correct and executable? (\(URL(fileURLWithPath: clientPath).absoluteString))")
                }
                
            }
        } else {
            running += 1
            started += 1
            let process = Process()
            if #available(OSX 10.13, *) {
                process.executableURL = URL(fileURLWithPath: clientPath).absoluteURL
            } else {
                process.launchPath = URL(fileURLWithPath: clientPath).absoluteString
            }
            process.arguments = ["-u", "http://localhost:50123", "-t", "3000000"]
            process.standardOutput = FileHandle(forWritingAtPath: "/dev/null")
            process.terminationHandler = { process in
                self.finished += 1
                self.running -= 1
                if self.finished >= self.roundsPerMutation {
                    self.printStatistics()
                } else {
                    while self.running < PARALLEL_CLIENTS && self.started < self.roundsPerMutation {
                        self.startClients()
                    }
                }
            }
            do {
                if #available(OSX 10.13, *) {
                    try process.run()
                } else {
                    process.launch()
                }
            } catch {
                fatalError("Could not launch client! Aborting! Is the path correct and executable? (\(URL(fileURLWithPath: clientPath).absoluteString))")
            }
        }
        clientStarter.signal()
    }
    
    func printStatistics() {
        print("Generated statistics:\n")
        print("The score was \(scoreSum) with an average of \(Float(scoreSum) / Float((mutations - 1) * roundsPerMutation)).\n")
        print("Of the \(gamesPerMutation) games a total of \(trainers[0].mutations[0].wins) were won and \(gamesPerMutation - trainers[0].mutations[0].wins) were lost.")
        print("This means \(Double(Int(Double(trainers[0].mutations[0].wins) * 100 / Double(gamesPerMutation))) / 100)% were won.")
        exit(0)
    }
}
