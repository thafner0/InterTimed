//
//  Timepoint.swift
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
            temporality = .pass(at: Date().addingTimeInterval(TimeInterval.random(in: -60...60)))
        }
        
        return Timepoint(name: "Random", temporality: temporality)
    }
    
    public enum Temporality: Equatable {
        case start(departureTime: Date)
        case pass(at: Date)
        case prolonged(arrival: Date, departure: Date)
        case awaitingArrival
        case awaitingDeparture(afterArrival: Date)
        case end(arrivalTime: Date)
        
        public var arrivalTime: Date? {
            switch self {
            case .pass(at: let arrival), .prolonged(arrival: let arrival, departure: _), .awaitingDeparture(afterArrival: let arrival), .end(arrivalTime: let arrival):
                return arrival
            case .awaitingArrival, .start(departureTime: _):
                return nil
            }
        }
        
        public var departureTime: Date? {
            switch self {
            case .pass(at: let departure), .prolonged(arrival: _, departure: let departure), .start(departureTime: let departure):
                return departure
            case .awaitingArrival, .awaitingDeparture(afterArrival: _), .end(arrivalTime: _):
                return nil
            }
        }
    }
}
