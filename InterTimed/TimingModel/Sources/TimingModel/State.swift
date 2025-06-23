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
    func depart(model: IntervalSeriesModel) throws
    func arriveAtStop(model: IntervalSeriesModel) throws
    func endSeriesReset(model: IntervalSeriesModel) throws
}

public struct Ready: IntervalState {
    public let canDepart = true
    public let canArriveAtStop = true
    public let canEndSeriesReset = false
    
    public func depart(model: IntervalSeriesModel) {
        let start = Date()
        let origin = Timepoint(name: "Location \(model.timepoints.count + 1)", temporality: .instant(passingAt: start))
        model.timepoints.append(origin)
        model.state = TimingTravel()
    }
    
    public func arriveAtStop(model: IntervalSeriesModel) {
        let start = Date()
        model.state = TimingDwell(arrivalTime: start)
    }
    
    public func endSeriesReset(model: IntervalSeriesModel) throws {
        throw IntervalSeriesModel.ModelError.invalidStateTransition(reason: "Cannot reset timer that's already reset.")
    }
}

public struct TimingTravel: IntervalState {
    public let canDepart = true
    public let canArriveAtStop = true
    public let canEndSeriesReset = true
    
    public func depart(model: IntervalSeriesModel) {
        let departureTime = Date()
        
        let next = Timepoint(name: "Location \(model.timepoints.count + 1)", temporality: .instant(passingAt: departureTime))
        model.timepoints.append(next)
        model.state = TimingTravel()
    }
    
    public func arriveAtStop(model: IntervalSeriesModel) {
        let arrivalTime = Date()
        
        model.state = TimingDwell(arrivalTime: arrivalTime)
    }
    
    public func endSeriesReset(model: IntervalSeriesModel) {
        let arrivalTime = Date()
        
        let last = Timepoint(name: "Location \(model.timepoints.count  + 1)", temporality: .instant(passingAt: arrivalTime))
        model.timepoints.append(last)
        model.state = StoppedWithData()
    }
}

public struct TimingDwell: IntervalState {
    public let arrivalTime: Date
    
    public let canDepart = true
    public let canArriveAtStop = false
    public let canEndSeriesReset = true

    private func endDwell(for model: IntervalSeriesModel) {
        let departureTime = Date()
        
        let timepoint = Timepoint(name: "Location \(model.timepoints.count + 1)", temporality: .prolonged(arrival: arrivalTime, departure: departureTime))
        model.timepoints.append(timepoint)
    }
    
    public func depart(model: IntervalSeriesModel) {
        endDwell(for: model)
        
        model.state = TimingTravel()
    }
    
    public func arriveAtStop(model: IntervalSeriesModel) throws {
        throw IntervalSeriesModel.ModelError.invalidStateTransition(reason: "Cannot dwell at two places without traveling between them.")
    }
    
    public func endSeriesReset(model: IntervalSeriesModel) {
        endDwell(for: model)
        
        model.state = StoppedWithData()
    }
    
    
}

public struct StoppedWithData: IntervalState {
    public let canDepart = false
    public let canArriveAtStop = false
    public let canEndSeriesReset = true
    
    public func depart(model: IntervalSeriesModel) throws {
        throw IntervalSeriesModel.ModelError.invalidStateTransition(reason: "Must reset timer before starting new series.")
    }
    
    public func arriveAtStop(model: IntervalSeriesModel) throws {
        throw IntervalSeriesModel.ModelError.invalidStateTransition(reason: "Must reset timer before starting new series.")
    }
    
    public func endSeriesReset(model: IntervalSeriesModel) {
        model.timepoints.removeAll()
        model.state = Ready()
    }
}
