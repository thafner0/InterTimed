//
//  Timepoint.swift
//  TimingModel
//
//  Created by Trevor Hafner on 14/06/2025.
//

import Foundation

@Observable
@dynamicMemberLookup
public class Timepoint: Equatable, Identifiable, CustomStringConvertible {
    public var metadata: TimepointMetadata
    public internal(set) var temporality: Temporality
    public var id = UUID()
    
    init(metadata: TimepointMetadata, temporality: Temporality) {
        self.metadata = metadata
        self.temporality = temporality
    }
    
    public static func ==(lhs: Timepoint, rhs: Timepoint) -> Bool {
        return lhs.metadata == rhs.metadata && lhs.temporality == rhs.temporality
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
        
        return Timepoint(metadata: TimepointMetadata(locationDescription: "Random"), temporality: temporality)
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
    
    public var description: String {
        switch temporality {
        case .start(let departureTime):
            return "Started at \(self.locationDescription), departing at \(departureTime)"
        case .pass(let passTime):
            return "Passed \(self.locationDescription) at \(passTime)"
        case .prolonged(let arrival, let departure):
            return "Served \(self.locationDescription), arriving at \(arrival) and departing at \(departure)"
        case .awaitingArrival:
            return "Awaiting arrival at \(self.locationDescription)"
        case .awaitingDeparture(let arrival):
            return "Arrived at \(self.locationDescription) at \(arrival); awaiting departure"
        case .end(let arrivalTime):
            return "Ended at \(self.locationDescription), arriving at \(arrivalTime)"
        }
    }
    
    public subscript<T>(dynamicMember member: WritableKeyPath<TimepointMetadata, T>) -> T {
        get {
            metadata[keyPath: member]
        }
        set {
            metadata[keyPath: member] = newValue
        }
    }
}
