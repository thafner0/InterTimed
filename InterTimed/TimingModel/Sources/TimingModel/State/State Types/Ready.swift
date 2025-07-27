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
        let origin = Timepoint(metadata: TimepointMetadata(locationDescription: "Location1"), temporality: .start(departureTime: start))
        model.timepoints.append(origin)
        
        model.state = TimingLeg(nextTimepointMetadata: TimepointMetadata(locationDescription: "Location2"))
    }
    
    public func arriveAtStop(model: IntervalSeries) {
        let start = Date()
        
        model.state = TimingDwell(arrivalTime: start, timepointMetadata: TimepointMetadata(locationDescription: "Location1"))
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
    
    public var description: String {
        "Ready"
    }
}
