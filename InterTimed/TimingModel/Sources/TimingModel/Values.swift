//
//  IntervalSeriesValueTypes.swift
//  TimingModel
//
//  Created by Trevor Hafner on 14/06/2025.
//

import Foundation

@Observable
public class Timepoint: Equatable, Identifiable {
    public var name: String
    public internal(set) var temporality: Temporality
    public var id = UUID()
    
    init(name: String, temporality: Temporality) {
        self.name = name
        self.temporality = temporality
    }
    
    public static func ==(lhs: Timepoint, rhs: Timepoint) -> Bool {
        return lhs.name == rhs.name && lhs.temporality == rhs.temporality
    }
    
    public static var random: Timepoint {
        let isStopping = Bool.random()
        let temporality: Temporality
        switch isStopping {
        case true:
            temporality = .prolonged(arrival: Date().addingTimeInterval(-TimeInterval.random(in: 10...60)), departure: Date().addingTimeInterval(TimeInterval.random(in: 10...60)))
        case false:
            temporality = .instant(passingAt: Date().addingTimeInterval(TimeInterval.random(in: -60...60)))
        }
        
        return Timepoint(name: "Random", temporality: temporality)
    }
}

public struct Leg: Equatable, Identifiable {
    public internal(set) var start: Timepoint
    public internal(set) var end: Timepoint
    
    public var id: UUID { start.id }
    
    public static var random: Leg {
        let start = Timepoint(name: "Start", temporality: .instant(passingAt: Date()))
        let end = Timepoint(name: "End", temporality: .instant(passingAt: Date().addingTimeInterval(.random(in: 60...6000))))
        return Leg(start: start, end: end)
    }
}

public extension Array where Element == Timepoint {
    var legs: [Leg] {
        let zip = zip(self.dropLast(), self.dropFirst())
        
        var legs = [Leg]()
        for (start, end) in zip {
            legs.append(Leg(start: start, end: end))
        }
        
        return legs
    }
}

public enum Temporality: Equatable {
    case instant(passingAt: Date)
    case prolonged(arrival: Date, departure: Date)
    
    public var arrivalTime: Date {
        switch self {
        case .instant(passingAt: let arrival), .prolonged(arrival: let arrival, departure: _):
            return arrival
        }
    }
    
    public var departureTime: Date {
        switch self {
        case .instant(passingAt: let departure), .prolonged(arrival: _, departure: let departure):
            return departure
        }
    }
    
    public var dwellDuration: Duration? {
        switch self {
        case .instant(passingAt: _):
            return nil
        case .prolonged(arrival: let arrival, departure: let departure):
            return Duration.seconds(arrival.distance(to: departure))
        }
    }
}
