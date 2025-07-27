//
//  TimingDwell.swift
//  TimingModel
//
//  Created by Trevor Hafner on 6/26/25.
//

import Foundation

public struct TimingDwell: IntervalState {
    public let arrivalTime: Date
    public let timepointMetadata: TimepointMetadata
    
    public let canDepart = true
    public let canArriveAtStop = false
    public let canEndSeriesReset = true
    public let isTiming = true
    public let canUndo = true

    private func endDwell(for model: IntervalSeries) throws {
        let departureTime = Date()
        
        model.timepoints.append(Timepoint(metadata: timepointMetadata, temporality: .prolonged(arrival: arrivalTime, departure: departureTime)))
    }
    
    public func depart(model: IntervalSeries) throws {
        try endDwell(for: model)
        
        model.state = TimingLeg(nextTimepointMetadata: TimepointMetadata(locationDescription: "Location\(model.timepoints.count + 1)"))
    }
    
    public func arriveAtStop(model: IntervalSeries) throws {
        throw ImproperStateTransition.immediatelySuccessiveDwellsNotPermitted
    }
    
    public func endSeriesReset(model: IntervalSeries) throws {
        try endDwell(for: model)
        
        model.state = StoppedWithData()
    }
    
    public func swapIntervalType(model: IntervalSeries) throws {
        let temporality: Timepoint.Temporality
        if !model.timepoints.isEmpty {
            temporality = .pass(at: arrivalTime)
        } else {
            temporality = .start(departureTime: arrivalTime)
        }
        model.timepoints.append(Timepoint(metadata: timepointMetadata, temporality: temporality))
        
        model.state = TimingLeg(nextTimepointMetadata: TimepointMetadata(locationDescription: "Location\(model.timepoints.count + 1)"))
    }
    
    public func resetCurrentIntervalStart(model: IntervalSeries) throws {
        let newArrival = Date()
        
        model.state = TimingDwell(arrivalTime: newArrival, timepointMetadata: timepointMetadata)
    }
    
    public func undoPreviousAction(model: IntervalSeries) throws {
        if !model.timepoints.isEmpty {
            // previous interval was leg
            model.state = TimingLeg(nextTimepointMetadata: timepointMetadata)
        } else {
            // this is first interval
            model.state = Ready()
        }
    }
    
    public var description: String {
        "Timing Dwell starting at \(arrivalTime)"
    }
}
