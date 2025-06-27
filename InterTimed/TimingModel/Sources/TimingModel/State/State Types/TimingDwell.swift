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

    private func endDwell(for model: IntervalSeries) {
        let departureTime = Date()
        
        model.timepoints[model.timepoints.count - 1].temporality = .prolonged(arrival: arrivalTime, departure: departureTime)
        
    }
    
    public func depart(model: IntervalSeries) {
        endDwell(for: model)
        
        model.state = TimingLeg(model: model)
    }
    
    public func arriveAtStop(model: IntervalSeries) throws {
        throw ImproperStateTransition.immediatelySuccessiveDwellsNotPermitted
    }
    
    public func endSeriesReset(model: IntervalSeries) {
        endDwell(for: model)
        
        model.state = StoppedWithData()
    }
    
    public func swapIntervalType(model: IntervalSeries) throws {
        let arrivalDepartureTime = model.timepoints.last!.temporality.arrivalTime!
        
        if model.timepoints.count > 1 {
            model.timepoints.last!.temporality = .pass(at: arrivalDepartureTime)
        } else {
            model.timepoints.last!.temporality = .start(departureTime: arrivalDepartureTime)
        }
        
        model.state = TimingLeg(model: model)
    }
    
    public func resetCurrentIntervalStart(model: IntervalSeries) throws {
        let newArrival = Date()
        
        model.timepoints.last!.temporality = .awaitingDeparture(afterArrival: newArrival)
        model.state = TimingDwell(arrivalTime: newArrival)
    }
    
    public func undoPreviousAction(model: IntervalSeries) throws {
        if model.timepoints.count > 1 {
            // previous interval was leg
            model.timepoints.last!.temporality = .awaitingArrival
            model.state = TimingLeg()
        } else {
            // this is first interval
            model.timepoints.removeAll()
            model.state = Ready()
        }
    }
}