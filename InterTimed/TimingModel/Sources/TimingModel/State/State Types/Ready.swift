//
//  Ready.swift
//  TimingModel
//
//  Created by Trevor Hafner on 6/26/25.
//

import Foundation

public struct Ready: IntervalState {
    public let canDepart = true
    public let canArriveAtStop = true
    public let canEndSeriesReset = false
    public let isTiming = false
    public let canUndo = false

    public func depart(model: IntervalSeries) {
        let start = Date()
        let origin = Timepoint(name: "Location1", temporality: .start(departureTime: start))
        model.timepoints.append(origin)
        
        model.state = TimingLeg(model: model)
    }
    
    public func arriveAtStop(model: IntervalSeries) {
        let start = Date()
        
        let origin = Timepoint(name: "Location1", temporality: .awaitingDeparture(afterArrival: start))
        model.timepoints.append(origin)
        
        model.state = TimingDwell(arrivalTime: start)
    }
    
    public func endSeriesReset(model: IntervalSeries) throws {
        throw ImproperStateTransition.cannotResetAlreadyResetTimer
    }
    
    public func swapIntervalType(model: IntervalSeries) throws {
        throw ImproperStateTransition.cannotSwapTimingIntervalTypeWhileStopped
    }
    
    public func resetCurrentIntervalStart(model: IntervalSeries) throws {
        throw ImproperStateTransition.cannotResetCurrentIntervalWhileStopped
    }
    
    public func undoPreviousAction(model: IntervalSeries) throws {
        throw ImproperStateTransition.nothingToUndo
    }
}