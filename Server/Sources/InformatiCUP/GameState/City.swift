//
//  City.swift
//  InformatiCUP-2020
//
//  Created by Jonas Peeters on 17.01.20.
//

import Foundation

/// Object representing the known information of a city
struct City {
    /// Name of the city
    var name: String
    /// Population of the city in thousands
    var population: Float
    /// Names of cities that this city has airplane routes to
    var connections: [String]
    /// Value for the economic strength of the city
    var economy: Float
    /// Value for the government strength of the city
    var government: Float
    /// Value for the hygiene strength of the city
    var hygiene: Float
    /// Value for the awareness strength of the city
    var awareness: Float
    /// Events specifically of this city
    var events: [Event] = []
    /// Names of pathogens in this city
    var pathogens: [String] = []
    
    /// Create a new city
    /// - Parameter data: Dictionary of a city from the JSON string from the client
    init(_ data: [String : Any]) {
        name = data["name"] as! String
        population = (data["population"] as! NSNumber).floatValue
        connections = data["connections"] as! [String]
        economy = plusMinusToFloat(data["economy"] as! String)
        government = plusMinusToFloat(data["government"] as! String)
        hygiene = plusMinusToFloat(data["hygiene"] as! String)
        awareness = plusMinusToFloat(data["awareness"] as! String)
        if data.keys.contains("events") {
            for e in data["events"] as! [[String : Any]] {
                events.append(createEventFrom(e))
                if let e = events.last! as? OutbreakEvent {
                    pathogens.append(e.pathogen.name)
                }
            }
        }
    }
}
