//
//  IntervalSeriesValueTypes.swift
//  InterTimed
//
//  Created by Trevor Hafner on 14/06/2025.
//

import Foundation

struct Timepoint: Equatable {
    var name: String
    var temporality: Temporality
}

struct Interval: Equatable, Identifiable {
    var type: Type
    var id: Int
    
    enum `Type`: Equatable {
        case travel(duration: Duration)
        case dwell(duration: Duration?, locationName: String)
    }
}

enum Temporality: Equatable {
    case instant(passingAt: Date)
    case prolonged(arrival: Date, departure: Date)
    
    var arrivalTime: Date {
        switch self {
        case .instant(passingAt: let arrival), .prolonged(arrival: let arrival, departure: _):
            return arrival
        }
    }
    
    var departureTime: Date {
        switch self {
        case .instant(passingAt: let departure), .prolonged(arrival: _, departure: let departure):
            return departure
        }
    }
    
    var dwellDuration: Duration? {
        switch self {
        case .instant(passingAt: _):
            return nil
        case .prolonged(arrival: let arrival, departure: let departure):
            return Duration.seconds(arrival.distance(to: departure))
        }
    }
}
