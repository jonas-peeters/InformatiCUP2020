//
//  Logic.swift
//  InformatiCUP-2020
//
//  Created by Jonas Peeters on 07.01.20.
//

import Foundation

/// Number of clients that run should at least run at a given time
let PARALLEL_CLIENTS = 41
/// Initial learning rate
let LEARNING_RATE: Float = 0.25

/// Predictions that were made over the last second
var predictions = 0

/// The game logic
class Logic {
    /// GPU accelerator used to speed up random number generation,
    let engine: CalculationEngine
    /// Network to prioritize pathogens
    let PPNetwork: NeuralNetwork
    /// Network to choose an action for a pathogen
    let PASNetwork: NeuralNetwork
    /// Network to select a city for an action for a pathogen
    let PACSNetwork: NeuralNetwork
    /// Network to select a city
    let CSNetwork: NeuralNetwork
    /// Network to select ana ction for a acity
    let CASNetwork: NeuralNetwork
    /// Trainer group for all networks
    let trainerGroup: NeuralNetworkGroupTrainer
    
    /// Initialize the logic
    init() {
        #if canImport(MetalKit)
        if #available(OSX 10.13, *), !forceCPU {
            engine = GPUEngine(mutations)
        } else {
            engine = CPUEngine(mutations)
        }
        #else
        engine = CPUEngine(mutations)
        #endif
        

        print("Loading networks...")
        PPNetwork = NeuralNetwork("PP", ifCantRead: [34, 20, 1], engine)
        PASNetwork = NeuralNetwork("PAS", ifCantRead: [34, 10, 2], engine)
        PACSNetwork = NeuralNetwork("PACS", ifCantRead: [27, 20, 1], engine)
        CSNetwork = NeuralNetwork("CS", ifCantRead: [28, 1], engine)
        CASNetwork = NeuralNetwork("CAS", ifCantRead: [28, 7], engine)
        print("Loaded networks")

        print("Initializing trainers...")
        trainerGroup = NeuralNetworkGroupTrainer([PPNetwork, PASNetwork, PACSNetwork, CSNetwork, CASNetwork], mutations, gamesPerMutation, LEARNING_RATE, engine)
        print("Initialized trainers")
    }
    
    /// Predict an action for a given game state
    ///
    /// As this is the main logic function and therefore pretty long the are comments inside explaining the individual sections
    ///
    /// - Parameters:
    ///   - gameState: The current game state
    ///   - mutationIndex: Index of the mutation
    func predict(for gameState: GameState, with mutationIndex: Int) -> Action {
        predictions += 1
        
        /// Check if this is the highest mutation index, used for creating the base score by always return EndRoundActions
        if mutationIndex == mutations - 1 && mode == .training {
            if gameState.outcome != "pending" {
                if (gameState.outcome == "loss") {
                    trainerGroup.report(Int(gameState.round), mutationIndex, false)
                } else {
                    trainerGroup.report(300 - Int(gameState.round), mutationIndex, true)
                }
            }
            return EndRoundAction()
        }
        
        /// Check if the game is finished
        /// If it is the score is recorded and an EndRoundAction ends the game
        if gameState.outcome != "pending" {
            if (gameState.outcome == "loss") {
                trainerGroup.report(Int(gameState.round), mutationIndex, false)
            } else {
                trainerGroup.report(300 - Int(gameState.round), mutationIndex, true)
            }
            return EndRoundAction()
        }
        
        /// Somehow sometimes games without any pathogens are created. This with catch these games
        if gameState.p.count == 0 {
            return EndRoundAction()
        }
        
        let points = gameState.points
        
        /// # 1. Block: Mediaction and Vaccines
        ///
        /// In this block the networks create priorities for the pathogens and select an action and a city
        /// if the priorities are high enough.
        
        let preInputs = gameState.PPuPASInputs(points)
        var pathogens: [Pathogen] = []
        var inputs: [[Float]] = []

        for (i, value) in preInputs.enumerated() {
            if value != nil {
                inputs.append(value!)
                pathogens.append(gameState.p[i])
            }
        }
        
        var actions: [Action] = []
        var savePoints = false
                
        if inputs.count != 0 {
            var pathogenPriorities: [Float] = trainerGroup.predict("PP", mutationIndex, inputs).map { output in
                output[0]
            }
            
            if pathogenPriorities.count == 0 {
                return EndRoundAction()
            }
            let sum = pathogenPriorities.reduce(0, { initial, value in initial + value })
            
            
            while actions.count == 0 && pathogenPriorities.count != 0 && !savePoints && pathogenPriorities.max()! > 0.7 {
                let priorityOne = pathogenPriorities.maxIndex()
                
                if Int(points) >= 5 {
                    let pasInput = gameState.PPuPASInputs(points * pathogenPriorities[priorityOne] / sum, pathogens[priorityOne])[0]!
                    let oneHotAction = trainerGroup.predict("PAS", mutationIndex, pasInput)
                                    
                    if oneHotAction.count == 0 {
                        return EndRoundAction()
                    }
                    
                    let actionIndex = oneHotAction.maxIndex()
                    
                    
                    switch actionIndex {
                    case 0: // Vaccine was selected
                        var available = false
                        var inDevelopment = false
                        for event in gameState.events {
                            if let e = event as? VaccineAvailableEvent {
                                if e.pathogen.name == pathogens[priorityOne].name {
                                    available = true
                                }
                            }
                            if let e = event as? VaccineInDevelopmentEvent {
                                if e.pathogen.name == pathogens[priorityOne].name {
                                    inDevelopment = true
                                }
                            }
                        }
                        if available { // Vaccine is available; select city for distribution
                            let cities = zip(gameState.cities, gameState.cities.map { (city: City) in
                                gameState.PACSInput(action: 0, city: city, pathogen: pathogens[priorityOne])
                            }).filter { (city, input: [Float]?) in
                                if let _ = input { return true } else { return false }
                            }
                            if cities.count == 0 { break }
                            var pacsInputs: [[Float]] = []
                            pacsInputs.reserveCapacity(cities.count)
                            for (_, input) in cities { pacsInputs.append(input!) }
                            
                            let output = trainerGroup.predict("PACS", mutationIndex, pacsInputs).map { out in out[0] }
                            if output.count == 0 {
                                return EndRoundAction()
                            }
                            
                            let cityIndex = output.maxIndex()
                            actions.append(DeployVaccineAction(pathogen: pathogens[priorityOne].name as String, city: cities[cityIndex].0.name as String))
                        } else if !inDevelopment { // Vaccine is unavailable and not in development; if enough points are available, develop it
                            let a = DevelopVaccineAction(pathogen: pathogens[priorityOne].name as String)
                            if Int(points) >= a.getPrice() {
                                actions.append(a)
                            } else {
                                savePoints = true
                            }
                        }
                        break
                    case 1: // Medication was selected
                        var available = false
                        var inDevelopment = false
                        for event in gameState.events {
                            if let e = event as? MedicationAvailableEvent {
                                if e.pathogen.name == pathogens[priorityOne].name {
                                    available = true
                                }
                            }
                            if let e = event as? MedicationInDevelopmentEvent {
                                if e.pathogen.name == pathogens[priorityOne].name {
                                    inDevelopment = true
                                }
                            }
                        }
                        if available { // Medication is available; select city for distribution
                            let cities = zip(gameState.cities, gameState.cities.map { (city: City) in
                                gameState.PACSInput(action: 1, city: city, pathogen: pathogens[priorityOne])
                            }).filter { (city, input: [Float]?) in
                                if let _ = input { return true } else { return false }
                            }
                            if cities.count == 0 { break }
                            var pacsInputs: [[Float]] = []
                            pacsInputs.reserveCapacity(cities.count)
                            for (_, input) in cities {
                                pacsInputs.append(input!)
                            }
                            
                            let output = trainerGroup.predict("PACS", mutationIndex, pacsInputs).map { out in out[0] }
                            if output.count == 0 {
                                return EndRoundAction()
                            }
                            
                            let cityIndex = output.maxIndex()
                            actions.append(DeployMedicationAction(pathogen: pathogens[priorityOne].name as String, city: cities[cityIndex].0.name as String))
                        } else if !inDevelopment { // Medication is unavailable and not in development; if enough points are available, develop it
                            let a = DevelopMedicationAction(pathogen: pathogens[priorityOne].name as String)
                            if Int(points) >= a.getPrice() {
                                actions.append(a)
                            } else {
                                savePoints = true
                            }
                        }
                        break
                    default: break
                    }
                }
                pathogenPriorities.remove(at: priorityOne)
                pathogens.remove(at: priorityOne)
            }
        }
        
        /// # 2. Block: City specific actions
        ///
        /// In this block the CS network creates priorities for each city.
        /// The CAS network the selects an action for the city with the highest priority.
            
        var highestPriority: Float = -1000
        
        if Int(points) >= 3 && !savePoints && (actions.count == 0 || gameState.error == 1) {
            let cityPriorities = trainerGroup.predict("CS", mutationIndex, gameState.CSuCASInput())
            let cityActions = trainerGroup.predict("CAS", mutationIndex, gameState.CSuCASInput())
            
            var action: Action? = nil
            
            var sorted = zip(cityPriorities, zip(cityActions, gameState.cities)).sorted(by: {
                $0.0[0] > $1.0[0]
            })
            
            while action == nil && highestPriority > 0.9 {
                highestPriority = sorted[0].0[0]
                let city = sorted[0].1.1
                let actionIndex = sorted[0].1.0.maxIndex()
                switch actionIndex {
                    case 0: // Quarantine
                        let a = PutUnderQuarantineAction(city: city.name as String, rounds: 1)
                    if a.getPrice() < Int(points) {
                        action = a
                    } else {
                        savePoints = true
                    }
                    case 1: // Close airport
                        if !city.events.contains(where: { event in
                            if let _ = event as? AirportClosedEvent {
                                return true
                            } else {
                                return false
                            }
                        }) {
                            let a = CloseAirportAction(city: city.name as String, rounds: 1)
                            if a.getPrice() < Int(points) {
                                action = a
                            } else {
                                savePoints = true
                            }
                        }
                    case 2: // Close connection
                        if city.connections.count > 0 {
                            var closedConnections: [String] = []
                            for event in city.events {
                                if let e = event as? ConnectionClosedEvent {
                                    closedConnections.append(e.city)
                                }
                            }
                            
                            var citySizes: [Float] = []
                            for c in city.connections {
                                if !closedConnections.contains(c) {
                                    citySizes.append(gameState.cityPopulations[c]!)
                                }
                            }
                            
                            let a = CloseConnectionAction(fromCity: city.name as String, toCity: city.connections[citySizes.maxIndex()] as String, rounds: 1)
                            if a.getPrice() < Int(points) {
                                action = a
                            } else {
                                savePoints = true
                            }
                        }
                    case 3: // Exert influence
                        if city.economy < 2 {
                            let a = ExertInfluenceAction(city: city.name as String)
                            if a.getPrice() < Int(points) {
                                action = a
                            } else {
                                savePoints = true
                            }
                        }
                    case 4: // Call election
                        if city.government < 2 {
                            let a = CallElectionsAction(city: city.name as String)
                            if a.getPrice() < Int(points) {
                                action = a
                            } else {
                                savePoints = true
                            }
                        }
                    case 5: // Apply hygienic measures
                        if city.hygiene < 2 {
                            let a = ApplyHygienicMeasuresAction(city: city.name as String)
                            if a.getPrice() < Int(points) {
                                action = a
                            } else {
                                savePoints = true
                            }
                        }
                    case 6: // Launch campaing
                        if city.awareness < 2 {
                            let a = LaunchCampaignAction(city: city.name as String)
                            if a.getPrice() < Int(points) {
                                action = a
                            } else {
                                savePoints = true
                            }
                        }
                    default: break
                }
                sorted.removeFirst()
            }
            
            if action == nil {
                action = EndRoundAction()
            }
            if highestPriority > 0.6 {
                actions.append(action!)
            }
        }
        
        actions.append(EndRoundAction())
        
        if gameState.error == 1 && actions.count > 0 {
            return actions[1]
        } else {
            return actions.first!
        }
    }
}

