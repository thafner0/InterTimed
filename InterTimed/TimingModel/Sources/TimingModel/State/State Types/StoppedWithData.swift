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
    }
    
    public func swapIntervalType(model: IntervalSeries) throws {
        throw ImproperStateTransition.cannotSwapTimingIntervalTypeWhileStopped
    }
    
    public func resetCurrentIntervalStart(model: IntervalSeries) throws {
        throw ImproperStateTransition.cannotResetCurrentIntervalWhileStopped
    }
    
    public func undoPreviousAction(model: IntervalSeries) throws {
        guard let lastTimepoint = model.timepoints.last else {
            throw InconsistentStateError.insufficientNumberOfTimepointsForState(minimumCounnt: 1)
        }
        
        switch lastTimepoint.temporality {
        case .end(arrivalTime: _):
            // previous interval was leg
            let metadata = lastTimepoint.metadata
            model.timepoints.removeLast()
            model.state = TimingLeg(nextTimepointMetadata: metadata)
        case .prolonged(arrival: let arrival, departure: _):
            // previous interval was dwell
            let metadata = lastTimepoint.metadata
            model.timepoints.removeLast()
            model.state = TimingDwell(arrivalTime: arrival, timepointMetadata: metadata)
        case let otherTemporality:
            throw InconsistentStateError.allIntervalsMustBeCompleteForState(noncompliantTemporality: otherTemporality)
        }
    }
    
    public var description: String {
        "Stopped With Data"
    }
}
