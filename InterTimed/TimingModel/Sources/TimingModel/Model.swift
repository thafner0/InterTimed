//
//  IntervalSeriesModel.swift
//  TimingModel
//
//  Created by Trevor Hafner on 6/15/25.
//

import Foundation

@Observable
public class IntervalSeriesModel {
    public var timepoints: [Timepoint] = []
    public var intervals: [Interval] {
        let adjacentTimepoints = zip(timepoints.dropLast(), timepoints.dropFirst())
        
        var intervals: [Interval] = []
        intervals.reserveCapacity(timepoints.count * 2 - 1)
        for (index, (first, second)) in adjacentTimepoints.enumerated() {
            intervals.append(Interval(type: .dwell(duration: first.temporality.dwellDuration, locationName: first.name), id: index))
            intervals.append(Interval(type: .travel(duration: Duration.seconds(first.temporality.departureTime.distance(to: second.temporality.arrivalTime))), id: -(index + 1)))
        }
        if let lastTimepoint = timepoints.last {
            intervals.append(Interval(type: .dwell(duration: lastTimepoint.temporality.dwellDuration, locationName: lastTimepoint.name), id: timepoints.count - 1))
        }
        
        return intervals
    }
    public internal(set) var state: any IntervalState = Ready()
    
    public func departForNextTimepoint() throws {
        try state.depart(model: self)
    }
    
    public func arriveAtStop() throws {
        try state.arriveAtStop(model: self)
    }
    
    public func endSeriesReset() throws {
        try state.endSeriesReset(model: self)
    }
    
    nonisolated public enum ModelError: Error, Equatable {
        case invalidStateTransition(reason: String)
    }
    
    public init() {}
}
