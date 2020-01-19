//
//  Actions.swift
//  InformatiCUP-2020
//
//  Created by Jonas Peeters on 17.01.20.
//

import Foundation

class Action {
    var type: String
    
    init(type: String) {
        self.type = type
    }
    
    func getPrice() -> Int {
        return 0
    }
    
    func toJSON() -> String {
        fatalError("Not implemented")
    }
}

class EndRoundAction: Action, Encodable {
    init() {
        super.init(type: "endRound")
    }
    
    override func getPrice() -> Int {
        return 0
    }
    
    override func toJSON() -> String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        let string = NSMutableString(string: String(data: data, encoding: .utf8)!)
        string.insert("\"type\":\"\(type)\"", at: string.length - 1)
        return string as String
    }
}

class PutUnderQuarantineAction: Action, Encodable {
    var city: String
    var rounds: Int
    
    init(city: String, rounds: Int) {
        self.city = city
        self.rounds = rounds
        super.init(type: "putUnderQuarantine")
    }
    
    override func getPrice() -> Int {
        return 10 * rounds + 20
    }
    
    override func toJSON() -> String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        let string = NSMutableString(string: String(data: data, encoding: .utf8)!)
        string.insert(", \"type\":\"\(type)\"", at: string.length - 1)
        return string as String
    }
}

class CloseAirportAction: Action, Encodable {
    var city: String
    var rounds: Int
    
    init(city: String, rounds: Int) {
        self.city = city
        self.rounds = rounds
        super.init(type: "closeAirport")
    }
    
    override func getPrice() -> Int {
        return 5 * rounds + 15
    }
    
    override func toJSON() -> String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        let string = NSMutableString(string: String(data: data, encoding: .utf8)!)
        string.insert(", \"type\":\"\(type)\"", at: string.length - 1)
        return string as String
    }
}

class CloseConnectionAction: Action, Encodable {
    var fromCity: String
    var toCity: String
    var rounds: Int
    
    init(fromCity: String, toCity: String, rounds: Int) {
        self.fromCity = fromCity
        self.toCity = toCity
        self.rounds = rounds
        super.init(type: "closeConnection")
    }
    
    override func getPrice() -> Int {
        return 3 * rounds + 3
    }
    
    override func toJSON() -> String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        let string = NSMutableString(string: String(data: data, encoding: .utf8)!)
        string.insert(", \"type\":\"\(type)\"", at: string.length - 1)
        return string as String
    }
}

class DevelopVaccineAction: Action, Encodable {
    var pathogen: String
    
    init(pathogen: String) {
        self.pathogen = pathogen
        super.init(type: "developVaccine")
    }
    
    override func getPrice() -> Int {
        return 40
    }
    
    override func toJSON() -> String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        let string = NSMutableString(string: String(data: data, encoding: .utf8)!)
        string.insert(", \"type\":\"\(type)\"", at: string.length - 1)
        return string as String
    }
}

class DevelopMedicationAction: Action, Encodable {
    var pathogen: String
    
    init(pathogen: String) {
        self.pathogen = pathogen
        super.init(type: "developMedication")
    }
    
    override func getPrice() -> Int {
        return 20
    }
    
    override func toJSON() -> String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        let string = NSMutableString(string: String(data: data, encoding: .utf8)!)
        string.insert(", \"type\":\"\(type)\"", at: string.length - 1)
        return string as String
    }
}

class DeployVaccineAction: Action, Encodable {
    var pathogen: String
    var city: String
    
    init(pathogen: String, city: String) {
        self.pathogen = pathogen
        self.city = city
        super.init(type: "deployVaccine")
    }
    
    override func getPrice() -> Int {
        return 5
    }
    
    override func toJSON() -> String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        let string = NSMutableString(string: String(data: data, encoding: .utf8)!)
        string.insert(", \"type\":\"\(type)\"", at: string.length - 1)
        return string as String
    }
}

class DeployMedicationAction: Action, Encodable {
    var pathogen: String
    var city: String
    
    init(pathogen: String, city: String) {
        self.pathogen = pathogen
        self.city = city
        super.init(type: "deployMedication")
    }
    
    override func getPrice() -> Int {
        return 10
    }
    
    override func toJSON() -> String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        let string = NSMutableString(string: String(data: data, encoding: .utf8)!)
        string.insert(", \"type\":\"\(type)\"", at: string.length - 1)
        return string as String
    }
}

class ExertInfluenceAction: Action, Encodable {
    var city: String
    
    init(city: String) {
        self.city = city
        super.init(type: "exertInfluence")
    }
    
    override func getPrice() -> Int {
        return 3
    }
    
    override func toJSON() -> String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        let string = NSMutableString(string: String(data: data, encoding: .utf8)!)
        string.insert(", \"type\":\"\(type)\"", at: string.length - 1)
        return string as String
    }
}

class CallElectionsAction: Action, Encodable {
    var city: String
    
    init(city: String) {
        self.city = city
        super.init(type: "callElections")
    }
    
    override func getPrice() -> Int {
        return 3
    }
    
    override func toJSON() -> String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        let string = NSMutableString(string: String(data: data, encoding: .utf8)!)
        string.insert(", \"type\":\"\(type)\"", at: string.length - 1)
        return string as String
    }
}

class ApplyHygienicMeasuresAction: Action, Encodable {
    var city: String
    
    init(city: String) {
        self.city = city
        super.init(type: "applyHygienicMeasures")
    }
    
    override func getPrice() -> Int {
        return 3
    }
    
    override func toJSON() -> String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        let string = NSMutableString(string: String(data: data, encoding: .utf8)!)
        string.insert(", \"type\":\"\(type)\"", at: string.length - 1)
        return string as String
    }
}

class LaunchCampaignAction: Action, Encodable {
    var city: String
    
    init(city: String) {
        self.city = city
        super.init(type: "launchCampain")
    }
    
    override func getPrice() -> Int {
        return 3
    }
    
    override func toJSON() -> String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        let string = NSMutableString(string: String(data: data, encoding: .utf8)!)
        string.insert(", \"type\":\"\(type)\"", at: string.length - 1)
        return string as String
    }
}
