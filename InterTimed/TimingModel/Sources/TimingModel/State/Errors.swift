//
//  Error.swift
//  TimingModel
//
//  Created by Trevor Hafner on 6/26/25.
//

import Foundation

public enum ImproperStateTransition: Error, Equatable {
    case cannotResetAlreadyResetTimer
    case cannotSwapTimingIntervalTypeWhileStopped
    case immediatelySuccessiveDwellsNotPermitted
    case mustResetTimerBeforeStartingAgain
    case cannotResetCurrentIntervalWhileStopped
    case nothingToUndo
}

public enum InconsistentStateError: Error, Equatable {
    case insufficientNumberOfTimepointsForState(minimumCounnt: Int)
    case allIntervalsMustBeCompleteForState(noncompliantTemporality: Timepoint.Temporality)
    case unexpectedTemporalityType(temporality: Timepoint.Temporality)
}
