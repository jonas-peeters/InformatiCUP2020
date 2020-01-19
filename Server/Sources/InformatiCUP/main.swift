import Foundation
import Kitura

/// Mode of the application
var mode: Mode = .predicting
/// Path to the informaticup client
var clientPath: String = "./binaries/ic20_darwin"
/// Number of mutations in a generation
var mutations = 30
/// Number of games per mutation / for statistic generation
var gamesPerMutation = 15
/// Force the cpu engine for testing purposes
var forceCPU = false

var index = 1
while index < ProcessInfo.processInfo.arguments.count {
    switch ProcessInfo.processInfo.arguments[index] {
    case "-m", "--mode":
        index += 1
        if index >= ProcessInfo.processInfo.arguments.count {
            print("Missing parameter for option \(ProcessInfo.processInfo.arguments[index - 1]). Possible options are (train|predict). Aborting!")
            exit(1)
        } else if ProcessInfo.processInfo.arguments[index] == "train" {
            mode = .training
        } else if ProcessInfo.processInfo.arguments[index] == "predict" {
            mode = .predicting
        } else if ProcessInfo.processInfo.arguments[index] == "stats" {
            mode = .statistics
            if !ProcessInfo.processInfo.arguments.contains("--games") {
                gamesPerMutation = 50
            }
        } else {
            print("Unknown mode \"\(ProcessInfo.processInfo.arguments[index])\"")
            exit(1)
        }
        break
    case "--mutations":
        index += 1
        if index >= ProcessInfo.processInfo.arguments.count {
            print("Missing parameter for option \(ProcessInfo.processInfo.arguments[index - 1]). Aborting!")
            exit(1)
        } else {
            do {
                mutations = try Int(value: ProcessInfo.processInfo.arguments[index])
            } catch {
                print("The number of mutations \(ProcessInfo.processInfo.arguments[index]) is invalid.")
                exit(1)
            }
        }
        break
    case "--games":
        index += 1
        if index >= ProcessInfo.processInfo.arguments.count {
            print("Missing parameter for option \(ProcessInfo.processInfo.arguments[index - 1]). Aborting!")
            exit(1)
        } else {
            do {
                gamesPerMutation = try Int(value: ProcessInfo.processInfo.arguments[index])
            } catch {
                print("The number of games \(ProcessInfo.processInfo.arguments[index]) is invalid.")
                exit(1)
            }
        }
        break
    case "-c", "--client":
        index += 1
        if index >= ProcessInfo.processInfo.arguments.count {
            print("Missing parameter for option \(ProcessInfo.processInfo.arguments[index - 1]). Aborting!")
            exit(1)
        } else {
            clientPath = ProcessInfo.processInfo.arguments[index]
        }
        break
    case "--force-cpu":
        forceCPU = true
        break
    case "-h", "--help":
        index += 1
        print("""
Help for InformatiCUP 2020!

Usage: ./InformatiCUP [arguments]

The following arguments are available:
  --mode, -m:   Set the mode of the server to (train|predict|
                stats). [Default: predict]

  --client, -c: Path to the InformatiCUP client. Required for
                predict mode. [Default: ./binaries/ic20_darwin]

  --help, -h:   Show this help

  --mutations:  The number of mutations that are created per
                generation. [Default: 30]

  --games:      Depends on mode:
                Training: The number of rounds each mutation
                     plays per generation. [Default: 15]
                Statistics: The number of games that will be
                     played to generate statistics. [Default: 50]

  --force-cpu:  Force the usage of the CPU engine even if a GPU
                is available. [Default: Disabled]

Additional information:
(1): In training and stat mode the program automatically starts
     instances of the client for training. You do not have to
     start them manually
(2): In the prediction mode -c is ignored. The client is not
     started automatically. You have to start them manually. The
     port is 50123.
""")
        exit(0)
        break
    default:
        print("Unknown option \(ProcessInfo.processInfo.arguments[index])")
        exit(1)
    }
    index += 1
}


/// Logic object
var logic = Logic()
/// Router for routing the requests
let router = Router()

router.post("/") { request, response, next in
    let mutationIndex = request.port - 50123
    let gameState = try! GameState(JSONSerialization.jsonObject(with: request.readString()!.data(using: .utf8)!, options: []) as! [String : Any])
    response.send(logic.predict(for: gameState, with: mutationIndex).toJSON())
    next()
}

if mode == .training {
    for i in 0..<mutations {
        Kitura.addHTTPServer(onPort: 50123 + i, with: router)
    }
} else {
    Kitura.addHTTPServer(onPort: 50123, with: router)
}

/// Time since the last prediction was made, if this number gets to large, the next generation is automatically triggered
var timeSinceLastPrediction = 0

/// Print the current learning process
func progressPrinter() {
    let totalGames = mode == .training ? mutations * gamesPerMutation : gamesPerMutation
    
    DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 1) {
        if !logic.trainerGroup.blocked {
            if predictions == 0 {
                timeSinceLastPrediction += 1
                if timeSinceLastPrediction > 60 {
                    logic.trainerGroup.nextGeneration()
                    timeSinceLastPrediction = 0
                }
            } else {
                timeSinceLastPrediction = 0
            }
            
            var string = "\(Float(Int(Float(logic.trainerGroup.finished) / Float(totalGames) * 10000)) / 100)% "
            
            while string.count < 8 {
                string += " "
            }
            string += "|"
            
            for i in 0..<100 {
                if Float(i) / 100 * Float(totalGames) < Float(logic.trainerGroup.finished) {
                    string += "█"
                } else if Float(i) / 100 * Float(totalGames) < Float(logic.trainerGroup.started) {
                    string += "—"
                } else {
                    string += "_"
                }
            }
            string += "| @ \(predictions) actions per second"
            print(string)
        }
        progressPrinter()
        predictions = 0
    }
}

if mode != .predicting {
    progressPrinter()
    logic.trainerGroup.startClients()
}


Kitura.run()
