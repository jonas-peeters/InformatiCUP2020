//
//  Pathogen.swift
//  InformatiCUP-2020
//
//  Created by Jonas Peeters on 17.01.20.
//

import Foundation

/// Object representing a pathogen
struct Pathogen {
    /// Name of the pathogen
    var name: String = ""
    /// Value for the infectivity
    var infectivity: Float = 0
    /// Value for the mobility
    var mobility: Float = 0
    /// Value for the duration
    var duration: Float = 0
    /// Value for the lethality
    var lethality: Float = 0
    /// Sum of prevalences over all cities
    var totalPrevalence: Float = 0
    /// List of cities that are infected with the prevalence of the infection
    var infectedCities: [(City, Float)] = []
    /// Value of priority (not the result of PP)
    var priority: Float = 0
    /// If a vaccine is available
    var vaccineAvailable = false
    /// If a vaccine is in development
    var vaccineInDevelopment = false
    /// If a medication is available
    var medicationAvailable = false
    /// If a medication is in developmnet
    var medicationInDevelopment = false
    /// In how many cities the vaccine has been deployed
    var vaccinesDeployed = 0
    /// In how many cities the medication has been deployed
    var medicationsDeployed = 0
    /// List of infected cities without medication together with the prevalence
    var citiesWithoutMedication: [(City, Float)] = []
    /// List of infected cities without vaccine together with the prevalence
    var citiesWithoutVaccine: [(City, Float)] = []
    /// If the pathogen will probably die on its own
    var willDie = false
    /// Amount of infected people
    var infectedPopulation: Float = 0
    /// Amount of people in infected cities, that are not infected
    var uninfectedPopulation: Float = 0
    /// A value of the connection strength of all the cities that are infected
    var connectionStrength: Float = 0
    
    
    /// Create a new pathogen
    /// - Parameter data: Dictionary of a pathogen from the JSON string from the client
    init(_ data: [String : String]) {
        name = data["name"]!
        infectivity = plusMinusToFloat(data["infectivity"]!)
        mobility = plusMinusToFloat(data["mobility"]!)
        duration = plusMinusToFloat(data["duration"]!)
        lethality = plusMinusToFloat(data["lethality"]!)
    }
    
    /// Convenience init for an empty pathogen
    init() {}
}
