//
//  TimingLeg.swift
//  TimingModel
//
//  Created by Trevor Hafner on 6/26/25.
//

import Foundation

public struct TimingLeg: IntervalState {
    public let nextTimepointMetadata: TimepointMetadata
    
    public let canDepart = true
    public let canArriveAtStop = true
    public let canEndSeriesReset = true
    public let isTiming = true
    public let canUndo = true

    public func depart(model: IntervalSeries) {
        let departureTime = Date()
        
        model.timepoints.append(Timepoint(metadata: nextTimepointMetadata, temporality: .pass(at: departureTime)))
        
        model.state = TimingLeg(nextTimepointMetadata: TimepointMetadata(locationDescription: "Location\(model.timepoints.count + 1)"))
    }
    
    public func arriveAtStop(model: IntervalSeries) {
        let arrivalTime = Date()
        
        model.state = TimingDwell(arrivalTime: arrivalTime, timepointMetadata: nextTimepointMetadata)
    }
    
    public func endSeriesReset(model: IntervalSeries) {
        let arrivalTime = Date()
        
        model.timepoints.append(Timepoint(metadata: nextTimepointMetadata, temporality: .end(arrivalTime: arrivalTime)))
        
        model.state = StoppedWithData()
    }
    
    public func swapIntervalType(model: IntervalSeries) throws {
        
        // The start of the current leg (ie departure from previous location)
        // is transformed into the start of new dwell interval (ie arrival at said previous location)
        let arrivalTime = model.timepoints.last!.temporality.departureTime!
        
        model.timepoints.removeLast()

        model.state = TimingDwell(arrivalTime: arrivalTime, timepointMetadata: nextTimepointMetadata)
    }
    
    public func resetCurrentIntervalStart(model: IntervalSeries) throws {
        let newDepartureTime = Date()
        
        let departurePoint = model.timepoints.last!
        
        switch departurePoint.temporality {
        case .pass(at: _), .start(departureTime: _):
            departurePoint.temporality = .pass(at: newDepartureTime)
        case .prolonged(arrival: let arrival, departure: _):
            departurePoint.temporality = .prolonged(arrival: arrival, departure: newDepartureTime)
        default:
            fatalError("Inconsistent state: must have departure timepoint before last.")
        }
    }
    
    public func undoPreviousAction(model: IntervalSeries) throws {
        let departurePoint = model.timepoints.last!
        
        switch departurePoint.temporality {
        case .prolonged(arrival: let arrival, departure: _):
            // previous interval was a dwell time
            let metadata = model.timepoints.last!.metadata
            model.timepoints.removeLast()
            model.state = TimingDwell(arrivalTime: arrival, timepointMetadata: metadata)
        case .start(departureTime: _):
            // this is first interval
            model.timepoints.removeAll()
            model.state = Ready()
        case .pass(at: _):
            // previous interval was a leg
            model.timepoints.last!.temporality = .awaitingArrival
        default:
            fatalError("Inconsistent state: must have departure timepoint before last.")
        }
    }
    
    init(nextTimepointMetadata: TimepointMetadata) {
        self.nextTimepointMetadata = nextTimepointMetadata
    }
    
    public var description: String {
        "Timing Leg"
    }
}
