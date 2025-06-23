//
//  IntervalSeriesModel.swift
//  InterTimed
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

public protocol IntervalState: Equatable {
    var canDepart: Bool { get }
    var canArriveAtStop: Bool { get }
    var canEndSeriesReset: Bool { get }
    func depart(model: IntervalSeriesModel) throws
    func arriveAtStop(model: IntervalSeriesModel) throws
    func endSeriesReset(model: IntervalSeriesModel) throws
}

public struct Ready: IntervalState {
    public let canDepart = true
    public let canArriveAtStop = true
    public let canEndSeriesReset = false
    
    public func depart(model: IntervalSeriesModel) {
        let start = Date()
        let origin = Timepoint(name: "Location \(model.timepoints.count + 1)", temporality: .instant(passingAt: start))
        model.timepoints.append(origin)
        model.state = TimingTravel()
    }
    
    public func arriveAtStop(model: IntervalSeriesModel) {
        let start = Date()
        model.state = TimingDwell(arrivalTime: start)
    }
    
    public func endSeriesReset(model: IntervalSeriesModel) throws {
        throw IntervalSeriesModel.ModelError.invalidStateTransition(reason: "Cannot reset timer that's already reset.")
    }
}

public struct TimingTravel: IntervalState {
    public let canDepart = true
    public let canArriveAtStop = true
    public let canEndSeriesReset = true
    
    public func depart(model: IntervalSeriesModel) {
        let departureTime = Date()
        
        let next = Timepoint(name: "Location \(model.timepoints.count + 1)", temporality: .instant(passingAt: departureTime))
        model.timepoints.append(next)
        model.state = TimingTravel()
    }
    
    public func arriveAtStop(model: IntervalSeriesModel) {
        let arrivalTime = Date()
        
        model.state = TimingDwell(arrivalTime: arrivalTime)
    }
    
    public func endSeriesReset(model: IntervalSeriesModel) {
        let arrivalTime = Date()
        
        let last = Timepoint(name: "Location \(model.timepoints.count  + 1)", temporality: .instant(passingAt: arrivalTime))
        model.timepoints.append(last)
        model.state = StoppedWithData()
    }
}

public struct TimingDwell: IntervalState {
    public let arrivalTime: Date
    
    public let canDepart = true
    public let canArriveAtStop = false
    public let canEndSeriesReset = true

    private func endDwell(for model: IntervalSeriesModel) {
        let departureTime = Date()
        
        let timepoint = Timepoint(name: "Location \(model.timepoints.count + 1)", temporality: .prolonged(arrival: arrivalTime, departure: departureTime))
        model.timepoints.append(timepoint)
    }
    
    public func depart(model: IntervalSeriesModel) {
        endDwell(for: model)
        
        model.state = TimingTravel()
    }
    
    public func arriveAtStop(model: IntervalSeriesModel) throws {
        throw IntervalSeriesModel.ModelError.invalidStateTransition(reason: "Cannot dwell at two places without traveling between them.")
    }
    
    public func endSeriesReset(model: IntervalSeriesModel) {
        endDwell(for: model)
        
        model.state = StoppedWithData()
    }
    
    
}

public struct StoppedWithData: IntervalState {
    public let canDepart = false
    public let canArriveAtStop = false
    public let canEndSeriesReset = true
    
    public func depart(model: IntervalSeriesModel) throws {
        throw IntervalSeriesModel.ModelError.invalidStateTransition(reason: "Must reset timer before starting new series.")
    }
    
    public func arriveAtStop(model: IntervalSeriesModel) throws {
        throw IntervalSeriesModel.ModelError.invalidStateTransition(reason: "Must reset timer before starting new series.")
    }
    
    public func endSeriesReset(model: IntervalSeriesModel) {
        model.timepoints.removeAll()
        model.state = Ready()
    }
}
