//
//  Events.swift
//  InformatiCUP-2020
//
//  Created by Jonas Peeters on 17.01.20.
//

import Foundation

/// Create the corrent event object from a dictionary based on the `type` value
/// - Parameter data: Dictionary of any event extracted from the JSON string from the client
func createEventFrom(_ data: [String : Any]) -> Event {
    switch data["type"] as! String {
        case "outbreak":                return OutbreakEvent(data)
        case "uprising":                return UprisingEvent(data)
        case "economicCrisis":          return EconomicCrisisEvent(data)
        case "electionsCalled":         return ElectionsCalledEvent(data)
        case "airportClosed":           return AirportClosedEvent(data)
        case "largeScalePanic":         return LargeScalePanicEvent(data)
        case "antiVaccinationism":      return AntiVaccinationismEvent(data)
        case "bioTerrorism":            return BioTerrorismEvent(data)
        case "connectionClosed":        return ConnectionClosedEvent(data)
        case "quarantine":              return QuarantineEvent(data)
        case "medicationDeployed":      return MedicationDeployedEvent(data)
        case "vaccineDeployed":         return VaccineDeployedEvent(data)
        case "vaccineInDevelopment":    return VaccineInDevelopmentEvent(data)
        case "vaccineAvailable":        return VaccineAvailableEvent(data)
        case "medicationInDevelopment": return MedicationInDevelopmentEvent(data)
        case "medicationAvailable":     return MedicationAvailableEvent(data)
        case "pathogenEncountered":     return PathogenEncounteredEvent(data)
        default:                        print(data)
                                        return UnknownEvent()
    }
}


/// Base representation for an event
class Event {
    /// Type of the event
    var type: String
    
    /// Initilize a base event
    /// - Parameter type: Type string of the event
    init(_ type: String) {
        self.type = type
    }
}

class UnknownEvent: Event {
    init() {
        super.init("Unkown")
    }
}

class PathogenEncounteredEvent: Event {
    var round: Float = 0
    var pathogen: Pathogen = Pathogen()
    
    init(_ data: [String : Any]) {
        round = (data["round"] as! NSNumber).floatValue
        pathogen = Pathogen(data["pathogen"] as! [String : String])
        super.init(data["type"] as! String)
    }
}

class OutbreakEvent: Event {
    var prevalence: Float = 0
    var sinceRound: Float = 0
    var pathogen: Pathogen = Pathogen()
    
    init(_ data: [String : Any]) {
        prevalence = (data["prevalence"] as! NSNumber).floatValue
        sinceRound = (data["sinceRound"] as! NSNumber).floatValue
        pathogen = Pathogen(data["pathogen"] as! [String : String])
        super.init(data["type"] as! String)
    }
    
    init() { super.init("outbreak") }
}

class UprisingEvent: Event {
    var paticipants: Float = 0
    var sinceRound: Float = 0
    
    init(_ data: [String : Any]) {
        paticipants = (data["paticipants"] as! NSNumber).floatValue
        sinceRound = (data["sinceRound"] as! NSNumber).floatValue
        super.init(data["type"] as! String)
    }
    
    init() { super.init("uprising") }
}

class EconomicCrisisEvent: Event {
    var sinceRound: Float = 0
    
    init(_ data: [String : Any]) {
        sinceRound = (data["sinceRound"] as! NSNumber).floatValue
        super.init(data["type"] as! String)
    }
    
    init() { super.init("economicCrisis") }
}

class ElectionsCalledEvent: Event {
    var round: Float = 0
    
    init(_ data: [String : Any]) {
        round = (data["round"] as! NSNumber).floatValue
        super.init(data["type"] as! String)
    }
}

class AirportClosedEvent: Event {
    var sinceRound: Float = 0
    var untilRound: Float = 0
    
    init(_ data: [String : Any]) {
        sinceRound = (data["sinceRound"] as! NSNumber).floatValue
        untilRound = (data["untilRound"] as! NSNumber).floatValue
        super.init(data["type"] as! String)
    }
}

class LargeScalePanicEvent: Event {
    var sinceRound: Float = 0
    
    init(_ data: [String : Any]) {
        sinceRound = (data["sinceRound"] as! NSNumber).floatValue
        super.init(data["type"] as! String)
    }
    
    init() { super.init("largeScalePanic") }
}

class AntiVaccinationismEvent: Event {
    var sinceRound: Float = 0
    
    init(_ data: [String : Any]) {
        sinceRound = (data["sinceRound"] as! NSNumber).floatValue
        super.init(data["type"] as! String)
    }
    
    init() { super.init("antiVaccinationism") }
}

class BioTerrorismEvent: Event {
    var round: Float = 0
    var pathogen: Pathogen = Pathogen()
    
    init(_ data: [String : Any]) {
        round = (data["round"] as! NSNumber).floatValue
        pathogen = Pathogen(data["pathogen"] as! [String : String])
        super.init(data["type"] as! String)
    }
    
    init() { super.init("bioTerrorism") }
}

class ConnectionClosedEvent: Event {
    var sinceRound: Float = 0
    var untilRound: Float = 0
    var city: String = ""
    
    init(_ data: [String : Any]) {
        sinceRound = (data["sinceRound"] as! NSNumber).floatValue
        untilRound = (data["untilRound"] as! NSNumber).floatValue
        city = data["city"] as! String
        super.init(data["type"] as! String)
    }
    
    init() { super.init("connectionClosed") }
}

class QuarantineEvent: Event {
    var sinceRound: Float = 0
    var untilRound: Float = 0
    
    init(_ data: [String : Any]) {
        sinceRound = (data["sinceRound"] as! NSNumber).floatValue
        untilRound = (data["untilRound"] as! NSNumber).floatValue
        super.init(data["type"] as! String)
    }
    
    init() { super.init("quarantine") }
}

class MedicationDeployedEvent: Event {
    var round: Float = 0
    var pathogen: Pathogen = Pathogen()
    
    init(_ data: [String : Any]) {
        round = (data["round"] as! NSNumber).floatValue
        pathogen = Pathogen(data["pathogen"] as! [String : String])
        super.init(data["type"] as! String)
    }
    
    init() { super.init("medicationDeployed") }
}

class VaccineDeployedEvent: Event {
    var round: Float = 0
    var pathogen: Pathogen = Pathogen()
    
    init(_ data: [String : Any]) {
        round = (data["round"] as! NSNumber).floatValue
        pathogen = Pathogen(data["pathogen"] as! [String : String])
        super.init(data["type"] as! String)
    }
    
    init() { super.init("vaccineDeployed") }
}

class MedicationInDevelopmentEvent: Event {
    var sinceRound: Float = 0
    var untilRound: Float = 0
    var pathogen: Pathogen = Pathogen()
    
    init(_ data: [String : Any]) {
        sinceRound = (data["sinceRound"] as! NSNumber).floatValue
        untilRound = (data["untilRound"] as! NSNumber).floatValue
        pathogen = Pathogen(data["pathogen"] as! [String : String])
        super.init(data["type"] as! String)
    }
    
    init() { super.init("medicationInDevelopment") }
}

class VaccineInDevelopmentEvent: Event {
    var sinceRound: Float = 0
    var untilRound: Float = 0
    var pathogen: Pathogen = Pathogen()
    
    init(_ data: [String : Any]) {
        sinceRound = (data["sinceRound"] as! NSNumber).floatValue
        untilRound = (data["untilRound"] as! NSNumber).floatValue
        pathogen = Pathogen(data["pathogen"] as! [String : String])
        super.init(data["type"] as! String)
    }
    
    init() { super.init("vaccineInDevelopment") }
}

class MedicationAvailableEvent: Event {
    var sinceRound: Float = 0
    var pathogen: Pathogen = Pathogen()
    
    init(_ data: [String : Any]) {
        sinceRound = (data["sinceRound"] as! NSNumber).floatValue
        pathogen = Pathogen(data["pathogen"] as! [String : String])
        super.init(data["type"] as! String)
    }
    
    init() { super.init("medicationAvailable") }
}

class VaccineAvailableEvent: Event {
    var sinceRound: Float = 0
    var pathogen: Pathogen = Pathogen()
    
    init(_ data: [String : Any]) {
        sinceRound = (data["sinceRound"] as! NSNumber).floatValue
        pathogen = Pathogen(data["pathogen"] as! [String : String])
        super.init(data["type"] as! String)
    }
    
    init() { super.init("vaccineAvailable") }
}
