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

enum Interval: Equatable {
    case travel(departureTime: Date, arrivalTime: Date)
    case dwell(arrivalTime: Date, departureTime: Date, locationName: String)
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
}
