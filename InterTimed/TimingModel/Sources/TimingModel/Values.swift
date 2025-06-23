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
}

public struct Leg: Equatable, Identifiable {
    public internal(set) var start: Timepoint
    public internal(set) var end: Timepoint
    
    public var id: UUID { start.id }
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

public struct Interval: Equatable, Identifiable {
    public var type: Type
    public var id: Int
    
    public enum `Type`: Equatable {
        case travel(duration: Duration)
        case dwell(duration: Duration?, locationName: String)
    }
    
    public init(type: `Type`, id: Int) {
        self.type = type
        self.id = id
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
