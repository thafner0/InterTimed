//
//  StoppedWithData.swift
//  TimingModel
//
//  Created by Trevor Hafner on 6/26/25.
//

import Foundation

public struct StoppedWithData: IntervalState {
    public let canDepart = false
    public let canArriveAtStop = false
    public let canEndSeriesReset = true
    public let isTiming = false
    public let canUndo = true
    
    public func depart(model: IntervalSeries) throws {
        throw ImproperStateTransition.mustResetTimerBeforeStartingAgain
    }
    
    public func arriveAtStop(model: IntervalSeries) throws {
        throw ImproperStateTransition.mustResetTimerBeforeStartingAgain
    }
    
    public func endSeriesReset(model: IntervalSeries) {
        model.timepoints.removeAll()
        model.state = Ready()
        log.notice("Timer Reset")
    }
    
    public func swapIntervalType(model: IntervalSeries) throws {
        throw ImproperStateTransition.cannotSwapTimingIntervalTypeWhileStopped
    }
    
    public func resetCurrentIntervalStart(model: IntervalSeries) throws {
        throw ImproperStateTransition.cannotResetCurrentIntervalWhileStopped
    }
    
    public func undoPreviousAction(model: IntervalSeries) throws {
        guard let lastTimepoint = model.timepoints.last else {
            log.fault("Inconsistent state: timer should not be in a Stopped With Data state without any timepoints")
            return
        }
        
        switch lastTimepoint.temporality {
        case .end(arrivalTime: _):
            // previous interval was leg
            lastTimepoint.temporality = .awaitingArrival
            model.state = TimingLeg()
            log.notice("Undone stop: current interval is now a leg to \(lastTimepoint.locationDescription, privacy: .private(mask: .hash))")
        case .prolonged(arrival: let arrival, departure: _):
            // previous interval was dwell
            lastTimepoint.temporality = .awaitingDeparture(afterArrival: arrival)
            model.state = TimingDwell(arrivalTime: arrival)
            log.notice("Undone stop: current interval is now a dwell at \(lastTimepoint.locationDescription, privacy: .private(mask: .hash))")
            log.info("Arrived at \(lastTimepoint.locationDescription, privacy: .private(mask: .hash)) at \(arrival, privacy: .public)")
        case let otherTemporality:
            log.fault("Inconsistent state: all intervals must be complete when a stopped state (last timepoint temporality: \(otherTemporality, privacy: .public))")
        }
    }
    
    public var description: String {
        "Stopped With Data"
    }
}
