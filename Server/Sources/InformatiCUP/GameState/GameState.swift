//
//  GameState.swift
//  InformatiCUP
//
//  Created by Jonas Peeters on 27.12.19.
//

import Foundation

let PATHOGEN_NAMES = ["N5-10", "Procrastinalgia", "Xenomonocythemia", "Hexapox", "Moricillus ☠", "Methanobrevibacter colferi", "Rhinonitis", "Saccharomyces cerevisiae mutans", "Phagum vidiianum", "Admiral Trips", "Plorps", "Coccus innocuus", "Φthisis", "Neurodermantotitis", "Shanty", "Azmodeus", "Influenza iutiubensis", "Bonulus eruptus", "Endoictus"].sorted()

/// Struct representing the current game state
struct GameState {
    /// Current round
    var round: Float
    /// Outcome of the game.
    ///  * `pending` while running
    ///  * `loss` if the game is over and counts as a loss
    ///  * `win` if the game is over and counts as a win
    var outcome: String
    /// Amount of points that can be spent
    /// Is 40 in round 1 and increases by 20 each round
    var points: Float
    /// Array of the 260 cities
    var cities: [City] = []
    /// Array of global events
    var events: [Event] = []
    /// Array of pathogen names for easier searching
    var pathogens: [String] = []
    /// Array of all pathogens (even if no one is infected any more)
    var p: [Pathogen] = []
    /// 0 if no error was reported
    /// 1 if the last action was invalid
    var error = 0
    /// Array of the populations of each city
    /// Is in the same order as `cities`
    var cityPopulations: [String : Float] = [:]
    /// Dictionary mapping the name of a city to the index of the respected city in `cities` and `cityPopulations`
    var cityNames: [String : Int] = [:]
    
    /// Initialize a game state from a dictionary
    /// - Parameter data: Dictionary created by parsing the JSON string from the client
    init(_ data: [String : Any]) {
        outcome = data["outcome"] as! String
        round = (data["round"] as! NSNumber).floatValue
        points = (data["points"] as! NSNumber).floatValue
        for (_, cityData) in data["cities"] as! [String : [String : Any]] {
            cities.append(City(cityData))
            cityPopulations[cities.last!.name] = cities.last!.population
            cityNames[cities.last!.name] = cities.count - 1
            for event in cities.last!.events {
                if let e = event as? BioTerrorismEvent {
                    if !pathogens.contains(e.pathogen.name) {
                        pathogens.append(e.pathogen.name)
                        p.append(e.pathogen)
                    }
                }
            }
        }
        for eventData in data["events"] as! [[String : Any]] {
            events.append(createEventFrom(eventData))
            if let e = events.last! as? PathogenEncounteredEvent {
                if !pathogens.contains(e.pathogen.name) {
                    pathogens.append(e.pathogen.name)
                    p.append(e.pathogen)
                }
            }
        }
        
        if data.keys.contains("error") {
            error = 1
        }
        
        pathogens.sort()
        p.sort(by: { $0.name < $1.name })
        
        pathogenPreparation()
    }
    
    mutating func pathogenPreparation() {
        for i in 0..<p.count {
            var pathogen = p[i]
                        
            for event in events {
                if let e = event as? VaccineInDevelopmentEvent {
                    if e.pathogen.name == pathogen.name {
                        pathogen.vaccineInDevelopment = true
                    }
                }
                if let e = event as? VaccineAvailableEvent {
                    if e.pathogen.name == pathogen.name {
                        pathogen.vaccineAvailable = true
                    }
                }
                if let e = event as? MedicationInDevelopmentEvent {
                    if e.pathogen.name == pathogen.name {
                        pathogen.medicationInDevelopment = true
                    }
                }
                if let e = event as? MedicationAvailableEvent {
                    if e.pathogen.name == pathogen.name {
                        pathogen.medicationAvailable = true
                    }
                }
            }
            
            
            for city in cities {
                var vaccine = false
                var medication = false
                var outbreak = false
                var relevantPrevalence: Float = 0
                for event in city.events {
                    if let e = event as? BioTerrorismEvent {
                        if e.pathogen.name == pathogen.name {
                            pathogen.infectedCities.append((city, 0.5))
                            relevantPrevalence = 0.5 * city.population
                            pathogen.infectedPopulation += 0.5 * city.population
                            pathogen.uninfectedPopulation += 0.5 * city.population
                        }
                    }
                    if let e = event as? OutbreakEvent {
                        if e.pathogen.name == pathogen.name {
                            if e.prevalence > 0 {
                                pathogen.totalPrevalence += e.prevalence
                                pathogen.infectedCities.append((city, e.prevalence))
                                pathogen.infectedPopulation += e.prevalence * city.population
                                pathogen.uninfectedPopulation += (1 - e.prevalence) * city.population
                                relevantPrevalence = Float(1 - abs(0.5 - e.prevalence)) * city.population
                                outbreak = true
                                pathogen.connectionStrength += Float(city.connections.count) * city.population
                            }
                        }
                    }
                    if let e = event as? VaccineDeployedEvent {
                        if e.pathogen.name == pathogen.name {
                            pathogen.vaccinesDeployed += 1
                            vaccine = true
                        }
                    }
                    if let e = event as? MedicationDeployedEvent {
                        if e.pathogen.name == pathogen.name {
                            pathogen.medicationsDeployed += 1
                            medication = true
                        }
                    }
                }
                if outbreak {
                    if !vaccine {
                        pathogen.citiesWithoutVaccine.append((city, relevantPrevalence))
                    }
                    if !medication {
                        pathogen.citiesWithoutMedication.append((city, pathogen.infectedPopulation))
                    }
                }
            }
            
            if pathogen.totalPrevalence == 0 || pathogen.mobility + pathogen.lethality + pathogen.infectivity + pathogen.duration < -2 {
                pathogen.willDie = true
            }
            
            p[i] = pathogen
        }
    }
    
    /// Create the input for the PP and PAS neural network for a specific pathogen
    /// - Parameters:
    ///   - points: The points available
    ///   - pathogen: The index of the pathogen in `pathogens`/`p`
    func PPuPASInputs(_ points: Float, _ pathogen: Pathogen? = nil) -> [[Float]?] {
        var list: [[Float]?] = []
        for p in self.p {
            if let pathogen = pathogen {
                if pathogen.name != p.name {
                    continue
                }
            }
            
            var info: [Float] = []
            
            for name in PATHOGEN_NAMES {
                if p.name == name {
                    info.append(1)
                } else {
                    info.append(0)
                }
            }
            
            
            info.append(contentsOf: [
                1-1/(1+points),
                p.infectivity,
                p.mobility,
                p.duration,
                p.lethality,
                p.vaccineInDevelopment ? 5 : -5,
                p.medicationInDevelopment ? 5 : -5,
                p.vaccineAvailable ? 5 : -5,
                p.medicationAvailable ? 5 : -5,
                Float(p.vaccinesDeployed) / Float(p.infectedCities.count),
                Float(p.medicationsDeployed) / Float(p.infectedCities.count),
                Float(p.infectedCities.count) / 260,
                1-1/(1 + p.connectionStrength / 100000),
                1-1/(1 + p.infectedPopulation / 1000),
                -1+1/(1 + p.uninfectedPopulation / 1000)
            ])

            if p.infectedPopulation > 0.0 {
                list.append(info)
            } else {
                list.append(nil)
            }
            
            if let pathogen = pathogen {
                if pathogen.name == p.name {
                    return [info]
                }
            }
        }
        
        return list
    }
    
    /// Create the input for the PAS neural network
    /// - Parameters:
    ///   - action: 0 if the action is vaccine deployment, 1 if the action is medicine deployment
    ///   - city: The city that the input should be create for
    ///   - pathogen: The pathogen
    func PACSInput(action: Int, city: City, pathogen: Pathogen) -> [Float]? {
        var list: [Float] = []
        
        var found = false
        for event in city.events {
            if let e = event as? OutbreakEvent {
                if e.pathogen.name == pathogen.name {
                    found = true
                    list.append(e.prevalence)
                    break
                }
            }
            if let e = event as? BioTerrorismEvent {
                if e.pathogen.name == pathogen.name {
                    found = true
                    list.append(1)
                    break
                }
            }
        }
        if !found {
            if action == 1 {
                return nil
            }
            list.append(-1)
            var tmp = false
            for cityName in city.connections {
                let city = cities[cityNames[cityName]!]
                if city.pathogens.contains(pathogen.name) {
                    tmp = true
                    break
                }
            }
            if !tmp {
                return nil
            }
        }
        found = false
        for event in city.events {
            if let e = event as? MedicationDeployedEvent {
                if e.pathogen.name == pathogen.name {
                    found = true
                    list.append(1)
                    if action == 1 {
                        return nil
                    }
                    break
                }
            }
        }
        if !found {
            list.append(-1)
        }
        found = false
        for event in city.events {
            if let e = event as? VaccineDeployedEvent {
                if e.pathogen.name == pathogen.name {
                    found = true
                    list.append(1)
                    if action == 0 {
                        return nil
                    }
                    break
                }
            }
        }
        if !found {
            list.append(-1)
        }
        
        var part = [action == 0 ? 1 : -1, action == 1 ? 1 : -1, pathogen.infectivity, pathogen.mobility, pathogen.duration, pathogen.lethality, 1-1/(1+city.population / 1000), city.economy, city.government, city.hygiene, city.awareness]
        
        for i in 0..<13 {
            if i < city.connections.count {
                let cityPopulation = cityPopulations[city.connections[i]]!
                part.append(1-1/(1+cityPopulation / 1000))
            } else {
                part.append(0)
            }
        }
        part.append(contentsOf: list)
        
        return part
    }

    
    /// Create the input for the CS and CAS neural network
    func CSuCASInput() -> [[Float]] {
        var list: [[Float]] = []
        
        for city in cities {
            var cityInfo: [Float] = []
            
            var medications: Float = 0
            for event in city.events {
                if let _ = event as? MedicationDeployedEvent {
                    medications += 1
                }
            }
            cityInfo.append(medications)
            
            var vaccines: Float = 0
            for event in city.events {
                if let _ = event as? VaccineDeployedEvent {
                    vaccines += 1
                }
            }
            cityInfo.append(vaccines)
            
            var infected: Float = 0
            var pathogenCount: Float = 0
            for event in city.events {
                if let e = event as? OutbreakEvent {
                    infected += e.prevalence
                    pathogenCount += 1
                }
            }
            cityInfo.append(infected)
            cityInfo.append(pathogenCount)
            
            var found = false
            for event in city.events {
                if let _ = event as? QuarantineEvent {
                    found = true
                    cityInfo.append(1)
                    break
                }
            }
            if !found {
                cityInfo.append(-1)
            }
            found = false
            for event in events {
                if let _ = event as? EconomicCrisisEvent {
                    found = true
                    cityInfo.append(1)
                    break
                }
            }
            if !found {
                cityInfo.append(-1)
            }
            found = false
            for event in events {
                if let _ = event as? LargeScalePanicEvent {
                    found = true
                    cityInfo.append(1)
                    break
                }
            }
            if !found {
                cityInfo.append(-1)
            }
            found = false
            for event in city.events {
                if let _ = event as? AntiVaccinationismEvent {
                    found = true
                    cityInfo.append(1)
                    break
                }
            }
            if !found {
                cityInfo.append(-1)
            }
            found = false
            for event in city.events {
                if let e = event as? UprisingEvent {
                    found = true
                    cityInfo.append(1-1/(1+e.paticipants))
                    break
                }
            }
            if !found {
                cityInfo.append(-1)
            }
            found = false
            for event in city.events {
                if let _ = event as? BioTerrorismEvent {
                    found = true
                    cityInfo.append(1)
                    break
                }
            }
            if !found {
                cityInfo.append(-1)
            }
            
            var part = [1-1/(1+city.population / 1000), city.economy, city.government, city.hygiene, city.awareness]
            
            var closedConnections: [String] = []
            for event in city.events {
                if let e = event as? ConnectionClosedEvent {
                    closedConnections.append(e.city)
                }
            }
            
            for i in 0..<13 {
                if i < city.connections.count {
                    if !closedConnections.contains(city.connections[i]) {
                        let cityPopulation = cityPopulations[city.connections[i]]!
                        part.append(1-1/(1+cityPopulation / 1000))
                    } else {
                        part.append(0)
                    }
                } else {
                    part.append(0)
                }
            }
            part.append(contentsOf: cityInfo)
            
            list.append(part)
        }
        
        return list
    }
    
}



