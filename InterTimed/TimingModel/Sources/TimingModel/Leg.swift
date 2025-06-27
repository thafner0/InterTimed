//
//  Leg.swift
//  TimingModel
//
//  Created by Trevor Hafner on 6/26/25.
//

import Foundation

public struct Leg: Equatable, Identifiable, CustomStringConvertible {
    public internal(set) var start: Timepoint
    public internal(set) var end: Timepoint
    
    public var id: UUID { start.id }
    
    public static var random: Leg {
        let start = Timepoint(name: "Start", temporality: .pass(at: Date()))
        let end = Timepoint(name: "End", temporality: .pass(at: Date().addingTimeInterval(.random(in: 60...6000))))
        return Leg(start: start, end: end)
    }
    
    public var description: String {
        let arrivalDescription: String
        
        if let arrivalTime = end.temporality.arrivalTime {
            arrivalDescription = "arrive \(arrivalTime.formatted())"
        } else  {
            arrivalDescription = "awaiting arrival"
        }
        
        return "Leg from \(start.locationDescription) (depart \(start.temporality.departureTime?.formatted() ?? "N/A")) to \(end.locationDescription) (\(arrivalDescription))"
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
