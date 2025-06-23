//
//  IntervalSeriesValueTypes.swift
//  TimingModel
//
//  Created by Trevor Hafner on 14/06/2025.
//

import Foundation

public struct Timepoint: Equatable {
    public var name: String
    public var temporality: Temporality
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
