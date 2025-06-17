//
//  IntervalSeriesModel.swift
//  InterTimed
//
//  Created by Trevor Hafner on 6/15/25.
//

import Foundation

class IntervalSeriesModel {
    var timepoints: [Timepoint] = []
    var intervals: [Interval] {
        let adjacentTimepoints = zip(timepoints.dropLast(), timepoints.dropFirst())
        
        var intervals: [Interval] = []
        intervals.reserveCapacity(timepoints.count * 2 - 1)
        for (first, second) in adjacentTimepoints {
            intervals.append(.dwell(duration: first.temporality.dwellDuration, locationName: first.name))
            intervals.append(.travel(duration: Duration.seconds(first.temporality.departureTime.distance(to: second.temporality.arrivalTime))))
        }
        if let lastTimepoint = timepoints.last {
            intervals.append(.dwell(duration: lastTimepoint.temporality.dwellDuration, locationName: lastTimepoint.name))
        }
        
        return intervals
    }
    fileprivate(set) var state: any IntervalState = Ready()
    
    func departForNextTimepoint() throws {
        try state.depart(model: self)
    }
    
    func arriveAtStop() throws {
        try state.arriveAtStop(model: self)
    }
    
    func endSeriesReset() throws {
        try state.endSeriesReset(model: self)
    }
    
    nonisolated enum ModelError: Error, Equatable {
        case invalidStateTransition(reason: String)
    }
}

protocol IntervalState: Equatable {
    func depart(model: IntervalSeriesModel) throws
    func arriveAtStop(model: IntervalSeriesModel) throws
    func endSeriesReset(model: IntervalSeriesModel) throws
}

struct Ready: IntervalState {
    func depart(model: IntervalSeriesModel) {
        let start = Date()
        let origin = Timepoint(name: "Location \(model.timepoints.count + 1)", temporality: .instant(passingAt: start))
        model.timepoints.append(origin)
        model.state = TimingTravel()
    }
    
    func arriveAtStop(model: IntervalSeriesModel) {
        let start = Date()
        model.state = TimingDwell(arrivalTime: start)
    }
    
    func endSeriesReset(model: IntervalSeriesModel) throws {
        throw IntervalSeriesModel.ModelError.invalidStateTransition(reason: "Cannot reset timer that's already reset.")
    }
}

struct TimingTravel: IntervalState {
    func depart(model: IntervalSeriesModel) {
        let departureTime = Date()
        
        let next = Timepoint(name: "Location \(model.timepoints.count + 1)", temporality: .instant(passingAt: departureTime))
        model.timepoints.append(next)
        model.state = TimingTravel()
    }
    
    func arriveAtStop(model: IntervalSeriesModel) {
        let arrivalTime = Date()
        
        model.state = TimingDwell(arrivalTime: arrivalTime)
    }
    
    func endSeriesReset(model: IntervalSeriesModel) {
        let arrivalTime = Date()
        
        let last = Timepoint(name: "Location \(model.timepoints.count  + 1)", temporality: .instant(passingAt: arrivalTime))
        model.timepoints.append(last)
        model.state = StoppedWithData()
    }
}

struct TimingDwell: IntervalState {
    let arrivalTime: Date
    
    private func endDwell(for model: IntervalSeriesModel) {
        let departureTime = Date()
        
        let timepoint = Timepoint(name: "Location \(model.timepoints.count + 1)", temporality: .prolonged(arrival: arrivalTime, departure: departureTime))
        model.timepoints.append(timepoint)
    }
    
    func depart(model: IntervalSeriesModel) {
        endDwell(for: model)
        
        model.state = TimingTravel()
    }
    
    func arriveAtStop(model: IntervalSeriesModel) throws {
        throw IntervalSeriesModel.ModelError.invalidStateTransition(reason: "Cannot dwell at two places without traveling between them.")
    }
    
    func endSeriesReset(model: IntervalSeriesModel) {
        endDwell(for: model)
        
        model.state = StoppedWithData()
    }
    
    
}

struct StoppedWithData: IntervalState {
    func depart(model: IntervalSeriesModel) throws {
        throw IntervalSeriesModel.ModelError.invalidStateTransition(reason: "Must reset timer before starting new series.")
    }
    
    func arriveAtStop(model: IntervalSeriesModel) throws {
        throw IntervalSeriesModel.ModelError.invalidStateTransition(reason: "Must reset timer before starting new series.")
    }
    
    func endSeriesReset(model: IntervalSeriesModel) {
        model.timepoints.removeAll()
        model.state = Ready()
    }
}
