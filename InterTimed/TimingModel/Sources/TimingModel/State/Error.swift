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
