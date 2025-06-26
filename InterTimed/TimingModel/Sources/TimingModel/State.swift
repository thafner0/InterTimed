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
    var canSwapIntervalType: Bool { get }
    
    func depart(model: IntervalSeriesModel) throws
    func arriveAtStop(model: IntervalSeriesModel) throws
    func endSeriesReset(model: IntervalSeriesModel) throws
    func swapIntervalType(model: IntervalSeriesModel) throws
}

public struct Ready: IntervalState {
    public let canDepart = true
    public let canArriveAtStop = true
    public let canEndSeriesReset = false
    public let canSwapIntervalType = false

    public func depart(model: IntervalSeriesModel) {
        let start = Date()
        let origin = Timepoint(name: "Location 1", temporality: .instant(passingAt: start))
        model.timepoints.append(origin)
        
        model.state = TimingLeg(model: model)
    }
    
    public func arriveAtStop(model: IntervalSeriesModel) {
        let start = Date()
        
        let origin = Timepoint(name: "Location 1", temporality: .awaitingDeparture(afterArrival: start))
        model.timepoints.append(origin)
        
        model.state = TimingDwell(arrivalTime: start)
    }
    
    public func endSeriesReset(model: IntervalSeriesModel) throws {
        throw IntervalSeriesModel.ModelError.invalidStateTransition(reason: "Cannot reset timer that's already reset.")
    }
    
    public func swapIntervalType(model: IntervalSeriesModel) throws {
        throw IntervalSeriesModel.ModelError.invalidStateTransition(reason: "Cannot swap interval type when not in state reflecting timing of interval.")
    }
}

public struct TimingLeg: IntervalState {
    public let canDepart = true
    public let canArriveAtStop = true
    public let canEndSeriesReset = true
    public let canSwapIntervalType = true

    public func depart(model: IntervalSeriesModel) {
        let departureTime = Date()
        
        model.timepoints[model.timepoints.count - 1].temporality = .instant(passingAt: departureTime)
        
        model.state = TimingLeg(model: model)
    }
    
    public func arriveAtStop(model: IntervalSeriesModel) {
        let arrivalTime = Date()
        
        model.timepoints[model.timepoints.count - 1].temporality = .awaitingDeparture(afterArrival: arrivalTime)
        
        model.state = TimingDwell(arrivalTime: arrivalTime)
    }
    
    public func endSeriesReset(model: IntervalSeriesModel) {
        let arrivalTime = Date()
        
        model.timepoints[model.timepoints.count - 1].temporality = .instant(passingAt: arrivalTime)
        
        model.state = StoppedWithData()
    }
    
    public func swapIntervalType(model: IntervalSeriesModel) throws {
        model.timepoints.removeLast()
        
        let arrivalTime = model.timepoints.last!.temporality.arrivalTime!
        
        model.timepoints.last!.temporality = .awaitingDeparture(afterArrival: arrivalTime)
        
        model.state = TimingDwell(arrivalTime: arrivalTime)
    }
    
    init(model: IntervalSeriesModel) {
        let next = Timepoint(name: "Location \(model.timepoints.count + 1)", temporality: .awaitingArrival)
        model.timepoints.append(next)
    }
}

public struct TimingDwell: IntervalState {
    public let arrivalTime: Date
    
    public let canDepart = true
    public let canArriveAtStop = false
    public let canEndSeriesReset = true
    public let canSwapIntervalType = true

    private func endDwell(for model: IntervalSeriesModel) {
        let departureTime = Date()
        
        model.timepoints[model.timepoints.count - 1].temporality = .prolonged(arrival: arrivalTime, departure: departureTime)
        
    }
    
    public func depart(model: IntervalSeriesModel) {
        endDwell(for: model)
        
        model.state = TimingLeg(model: model)
    }
    
    public func arriveAtStop(model: IntervalSeriesModel) throws {
        throw IntervalSeriesModel.ModelError.invalidStateTransition(reason: "Cannot dwell at two places without traveling between them.")
    }
    
    public func endSeriesReset(model: IntervalSeriesModel) {
        endDwell(for: model)
        
        model.state = StoppedWithData()
    }
    
    public func swapIntervalType(model: IntervalSeriesModel) throws {
        let arrivalDepartureTime = model.timepoints.last!.temporality.arrivalTime!
        
        model.timepoints.last!.temporality = .instant(passingAt: arrivalDepartureTime)
        
        model.state = TimingLeg(model: model)
    }
}

public struct StoppedWithData: IntervalState {
    public let canDepart = false
    public let canArriveAtStop = false
    public let canEndSeriesReset = true
    public let canSwapIntervalType = false
    
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
    
    public func swapIntervalType(model: IntervalSeriesModel) throws {
        throw IntervalSeriesModel.ModelError.invalidStateTransition(reason: "Cannot swap interval type while stopped.")
    }
}
