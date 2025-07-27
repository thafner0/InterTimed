//
//  TimingDwell.swift
//  TimingModel
//
//  Created by Trevor Hafner on 6/26/25.
//

import Foundation

public struct TimingDwell: IntervalState {
    public let arrivalTime: Date
    
    public let canDepart = true
    public let canArriveAtStop = false
    public let canEndSeriesReset = true
    public let isTiming = true
    public let canUndo = true

    private func endDwell(for model: IntervalSeries) throws {
        let departureTime = Date()
        guard let lastTimepoint = model.timepoints.last else {
            throw InconsistentStateError.insufficientNumberOfTimepointsForState(minimumCounnt: 1)
        }
        
        lastTimepoint.temporality = .prolonged(arrival: arrivalTime, departure: departureTime)
        
    }
    
    public func depart(model: IntervalSeries) throws {
        try endDwell(for: model)
        
        model.state = TimingLeg(model: model)
    }
    
    public func arriveAtStop(model: IntervalSeries) throws {
        throw ImproperStateTransition.immediatelySuccessiveDwellsNotPermitted
    }
    
    public func endSeriesReset(model: IntervalSeries) throws {
        try endDwell(for: model)
        
        model.state = StoppedWithData()
    }
    
    public func swapIntervalType(model: IntervalSeries) throws {
        guard let lastTimepoint = model.timepoints.last else {
            throw InconsistentStateError.insufficientNumberOfTimepointsForState(minimumCounnt: 1)
        }
        guard case .awaitingDeparture(afterArrival: let arrivalTime) = lastTimepoint.temporality else {
            throw InconsistentStateError.unexpectedTemporalityType(temporality: lastTimepoint.temporality)
        }
        
        if model.timepoints.count > 1 {
            lastTimepoint.temporality = .pass(at: arrivalTime)
        } else {
            lastTimepoint.temporality = .start(departureTime: arrivalTime)
        }
        
        model.state = TimingLeg(model: model)
    }
    
    public func resetCurrentIntervalStart(model: IntervalSeries) throws {
        let newArrival = Date()
        guard let currentTimepoint = model.timepoints.last else {
            throw InconsistentStateError.insufficientNumberOfTimepointsForState(minimumCounnt: 1)
        }
        
        currentTimepoint.temporality = .awaitingDeparture(afterArrival: newArrival)
        model.state = TimingDwell(arrivalTime: newArrival)
    }
    
    public func undoPreviousAction(model: IntervalSeries) throws {
        guard let lastTimepoint = model.timepoints.last else {
            throw InconsistentStateError.insufficientNumberOfTimepointsForState(minimumCounnt: 1)
        }
        
        if model.timepoints.count > 1 {
            // previous interval was leg
            lastTimepoint.temporality = .awaitingArrival
            model.state = TimingLeg()
        } else {
            // this is first interval
            model.timepoints.removeAll()
            model.state = Ready()
        }
    }
    
    public var description: String {
        "Timing Dwell starting at \(arrivalTime)"
    }
}
