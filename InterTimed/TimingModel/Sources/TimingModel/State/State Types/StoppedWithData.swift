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
    
    public func depart(model: IntervalSeriesModel) throws {
        throw ImproperStateTransition.mustResetTimerBeforeStartingAgain
    }
    
    public func arriveAtStop(model: IntervalSeriesModel) throws {
        throw ImproperStateTransition.mustResetTimerBeforeStartingAgain
    }
    
    public func endSeriesReset(model: IntervalSeriesModel) {
        model.timepoints.removeAll()
        model.state = Ready()
    }
    
    public func swapIntervalType(model: IntervalSeriesModel) throws {
        throw ImproperStateTransition.cannotSwapTimingIntervalTypeWhileStopped
    }
    
    public func resetCurrentIntervalStart(model: IntervalSeriesModel) throws {
        throw ImproperStateTransition.cannotResetCurrentIntervalWhileStopped
    }
    
    public func undoPreviousAction(model: IntervalSeriesModel) throws {
        switch model.timepoints.last!.temporality {
        case .end(arrivalTime: _):
            // previous interval was leg
            model.timepoints.last!.temporality = .awaitingArrival
            model.state = TimingLeg()
        case .prolonged(arrival: let arrival, departure: _):
            // previous interval was dwell
            model.timepoints.last!.temporality = .awaitingDeparture(afterArrival: arrival)
            model.state = TimingDwell(arrivalTime: arrival)
        default:
            fatalError("Inconsistent state: all intervals must be complete when in stopped state.")
        }
    }
}