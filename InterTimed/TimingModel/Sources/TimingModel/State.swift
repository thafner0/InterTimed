//
//  State.swift
//  TimingModel
//
//  Created by Trevor Hafner on 6/22/25.
//

import Foundation

public protocol IntervalState: Equatable {
    var canDepart: Bool { get }
    var canArriveAtStop: Bool { get }
    var canEndSeriesReset: Bool { get }
    var isTiming: Bool { get }
    var canUndo: Bool { get }
    
    func depart(model: IntervalSeriesModel) throws
    func arriveAtStop(model: IntervalSeriesModel) throws
    func endSeriesReset(model: IntervalSeriesModel) throws
    func swapIntervalType(model: IntervalSeriesModel) throws
    func resetCurrentIntervalStart(model: IntervalSeriesModel) throws
    func undoPreviousAction(model: IntervalSeriesModel) throws
}

public enum ImproperStateTransition: Error, Equatable {
    case cannotResetAlreadyResetTimer
    case cannotSwapTimingIntervalTypeWhileStopped
    case immediatelySuccessiveDwellsNotPermitted
    case mustResetTimerBeforeStartingAgain
    case cannotResetCurrentIntervalWhileStopped
    case nothingToUndo
}

public struct Ready: IntervalState {
    public let canDepart = true
    public let canArriveAtStop = true
    public let canEndSeriesReset = false
    public let isTiming = false
    public let canUndo = false

    public func depart(model: IntervalSeriesModel) {
        let start = Date()
        let origin = Timepoint(name: "Location1", temporality: .start(departureTime: start))
        model.timepoints.append(origin)
        
        model.state = TimingLeg(model: model)
    }
    
    public func arriveAtStop(model: IntervalSeriesModel) {
        let start = Date()
        
        let origin = Timepoint(name: "Location1", temporality: .awaitingDeparture(afterArrival: start))
        model.timepoints.append(origin)
        
        model.state = TimingDwell(arrivalTime: start)
    }
    
    public func endSeriesReset(model: IntervalSeriesModel) throws {
        throw ImproperStateTransition.cannotResetAlreadyResetTimer
    }
    
    public func swapIntervalType(model: IntervalSeriesModel) throws {
        throw ImproperStateTransition.cannotSwapTimingIntervalTypeWhileStopped
    }
    
    public func resetCurrentIntervalStart(model: IntervalSeriesModel) throws {
        throw ImproperStateTransition.cannotResetCurrentIntervalWhileStopped
    }
    
    public func undoPreviousAction(model: IntervalSeriesModel) throws {
        throw ImproperStateTransition.nothingToUndo
    }
}

public struct TimingLeg: IntervalState {
    public let canDepart = true
    public let canArriveAtStop = true
    public let canEndSeriesReset = true
    public let isTiming = true
    public let canUndo = true

    public func depart(model: IntervalSeriesModel) {
        let departureTime = Date()
        
        model.timepoints[model.timepoints.count - 1].temporality = .pass(at: departureTime)
        
        model.state = TimingLeg(model: model)
    }
    
    public func arriveAtStop(model: IntervalSeriesModel) {
        let arrivalTime = Date()
        
        model.timepoints[model.timepoints.count - 1].temporality = .awaitingDeparture(afterArrival: arrivalTime)
        
        model.state = TimingDwell(arrivalTime: arrivalTime)
    }
    
    public func endSeriesReset(model: IntervalSeriesModel) {
        let arrivalTime = Date()
        
        model.timepoints[model.timepoints.count - 1].temporality = .end(arrivalTime: arrivalTime)
        
        model.state = StoppedWithData()
    }
    
    public func swapIntervalType(model: IntervalSeriesModel) throws {
        model.timepoints.removeLast()
        
        // The start of the current leg (ie departure from previous location)
        // is transformed into the start of new dwell interval (ie arrival at said previous location)
        let arrivalTime = model.timepoints.last!.temporality.departureTime!
        
        model.timepoints.last!.temporality = .awaitingDeparture(afterArrival: arrivalTime)
        
        model.state = TimingDwell(arrivalTime: arrivalTime)
    }
    
    public func resetCurrentIntervalStart(model: IntervalSeriesModel) throws {
        let newDepartureTime = Date()
        
        let departurePoint = model.timepoints[model.timepoints.count - 2]
        
        switch departurePoint.temporality {
        case .pass(at: _), .start(departureTime: _):
            departurePoint.temporality = .pass(at: newDepartureTime)
        case .prolonged(arrival: let arrival, departure: _):
            departurePoint.temporality = .prolonged(arrival: arrival, departure: newDepartureTime)
        default:
            fatalError("Inconsistent state: must have departure timepoint before last.")
        }
    }
    
    public func undoPreviousAction(model: IntervalSeriesModel) throws {
        model.timepoints.removeLast()
        let departurePoint = model.timepoints.last!
        
        switch departurePoint.temporality {
        case .prolonged(arrival: let arrival, departure: _):
            // previous interval was a dwell time
            model.timepoints.last!.temporality = .awaitingDeparture(afterArrival: arrival)
            model.state = TimingDwell(arrivalTime: arrival)
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
    
    init(model: IntervalSeriesModel) {
        let next = Timepoint(name: "Location\(model.timepoints.count + 1)", temporality: .awaitingArrival)
        model.timepoints.append(next)
    }
    
    init() {}
}

public struct TimingDwell: IntervalState {
    public let arrivalTime: Date
    
    public let canDepart = true
    public let canArriveAtStop = false
    public let canEndSeriesReset = true
    public let isTiming = true
    public let canUndo = true

    private func endDwell(for model: IntervalSeriesModel) {
        let departureTime = Date()
        
        model.timepoints[model.timepoints.count - 1].temporality = .prolonged(arrival: arrivalTime, departure: departureTime)
        
    }
    
    public func depart(model: IntervalSeriesModel) {
        endDwell(for: model)
        
        model.state = TimingLeg(model: model)
    }
    
    public func arriveAtStop(model: IntervalSeriesModel) throws {
        throw ImproperStateTransition.immediatelySuccessiveDwellsNotPermitted
    }
    
    public func endSeriesReset(model: IntervalSeriesModel) {
        endDwell(for: model)
        
        model.state = StoppedWithData()
    }
    
    public func swapIntervalType(model: IntervalSeriesModel) throws {
        let arrivalDepartureTime = model.timepoints.last!.temporality.arrivalTime!
        
        if model.timepoints.count > 1 {
            model.timepoints.last!.temporality = .pass(at: arrivalDepartureTime)
        } else {
            model.timepoints.last!.temporality = .start(departureTime: arrivalDepartureTime)
        }
        
        model.state = TimingLeg(model: model)
    }
    
    public func resetCurrentIntervalStart(model: IntervalSeriesModel) throws {
        let newArrival = Date()
        
        model.timepoints.last!.temporality = .awaitingDeparture(afterArrival: newArrival)
        model.state = TimingDwell(arrivalTime: newArrival)
    }
    
    public func undoPreviousAction(model: IntervalSeriesModel) throws {
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
