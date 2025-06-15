//
//  IntervalSeriesStateModel.swift
//  InterTimed
//
//  Created by Trevor Hafner on 6/15/25.
//

import Foundation

class IntervalSeriesStateModel {
    private(set) var timepoints: [TimingPoint] = []
    fileprivate(set) var intervals: [Interval] = []
    fileprivate(set) var state: IntervalState = Ready()
    private var nextTimepointNumber = 1
    
    func departForNextTimepoint() throws {
        try state.depart(model: self)
    }
    
    func arriveAtStop() throws {
        try state.arriveAtStop(model: self)
    }
    
    func endSeriesReset() throws {
        try state.endSeriesReset(model: self)
    }
    
    fileprivate func addTimepoint() {
        let timepoint = TimingPoint(name: "Location \(nextTimepointNumber)")
        timepoints.append(timepoint)
        nextTimepointNumber += 1
    }
    
    enum ModelError: Error {
        case invalidStateTransition(reason: String)
        case noTimepointForDwellUpdate
    }
    
    fileprivate func updateLastTimepointDwell(to duration: Duration) throws {
        guard !timepoints.isEmpty else {
            throw ModelError.noTimepointForDwellUpdate
        }
        
        timepoints[timepoints.count - 1].dwellDuration = duration
    }
    
    fileprivate func reset() {
        timepoints.removeAll()
        intervals.removeAll()
        nextTimepointNumber = 1
    }
}

protocol IntervalState {
    func depart(model: IntervalSeriesStateModel) throws
    func arriveAtStop(model: IntervalSeriesStateModel) throws
    func endSeriesReset(model: IntervalSeriesStateModel) throws
}

struct Ready: IntervalState {
    func depart(model: IntervalSeriesStateModel) {
        let start = Date()
        model.addTimepoint()
        model.addTimepoint()
        model.state = TimingTravel(departureTime: start)
    }
    
    func arriveAtStop(model: IntervalSeriesStateModel) {
        let start = Date()
        model.addTimepoint()
        model.state = TimingDwell(arrivalTime: start)
    }
    
    func endSeriesReset(model: IntervalSeriesStateModel) throws {
        throw IntervalSeriesStateModel.ModelError.invalidStateTransition(reason: "Cannot reset timer that's already reset.")
    }
}

struct TimingTravel: IntervalState {
    let departureTime: Date
    
    private func endCurrentInterval(for model: IntervalSeriesStateModel) -> Date {
        let arrivalTime = Date()
        let completedInterval = Interval(departureTime: departureTime, arrivalTime: arrivalTime)
        model.intervals.append(completedInterval)
        return arrivalTime
    }
    
    func depart(model: IntervalSeriesStateModel) {
        let departureTime = endCurrentInterval(for: model)
        
        model.addTimepoint()
        model.state = TimingTravel(departureTime: departureTime)
    }
    
    func arriveAtStop(model: IntervalSeriesStateModel) {
        let arrivalTime = endCurrentInterval(for: model)
        
        model.state = TimingDwell(arrivalTime: arrivalTime)
    }
    
    func endSeriesReset(model: IntervalSeriesStateModel) {
        let _ = endCurrentInterval(for: model)
        
        model.state = StoppedWithData()
    }
    
    
}

struct TimingDwell: IntervalState {
    let arrivalTime: Date
    
    private func endDwell(for model: IntervalSeriesStateModel) -> Date {
        let departureTime = Date()
        let duration = Duration.seconds(arrivalTime.distance(to: departureTime))
        try! model.updateLastTimepointDwell(to: duration)
        return departureTime
    }
    
    func depart(model: IntervalSeriesStateModel) {
        let departureTime = endDwell(for: model)
        
        model.addTimepoint()
        model.state = TimingTravel(departureTime: departureTime)
    }
    
    func arriveAtStop(model: IntervalSeriesStateModel) throws {
        throw IntervalSeriesStateModel.ModelError.invalidStateTransition(reason: "Cannot dwell at two places without traveling.")
    }
    
    func endSeriesReset(model: IntervalSeriesStateModel) {
        _ = endDwell(for: model)
        
        model.state = StoppedWithData()
    }
    
    
}

struct StoppedWithData: IntervalState {
    func depart(model: IntervalSeriesStateModel) throws {
        throw IntervalSeriesStateModel.ModelError.invalidStateTransition(reason: "Must reset timer before starting new series.")
    }
    
    func arriveAtStop(model: IntervalSeriesStateModel) throws {
        throw IntervalSeriesStateModel.ModelError.invalidStateTransition(reason: "Must reset timer before starting new series.")
    }
    
    func endSeriesReset(model: IntervalSeriesStateModel) {
        model.reset()
        model.state = Ready()
    }
}
