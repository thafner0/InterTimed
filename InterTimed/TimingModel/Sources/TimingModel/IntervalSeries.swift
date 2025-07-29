//
//  IntervalSeries.swift
//  TimingModel
//
//  Created by Trevor Hafner on 6/15/25.
//

import Foundation

@Observable
public class IntervalSeries: CustomStringConvertible {
    public internal(set) var timepoints: [Timepoint] = []
    
    public internal(set) var state: any IntervalState = Ready()
    
    public internal(set) var startTime: Date? = nil
    
    public internal(set) var endTime: Date? = nil
    
    public func departForNextTimepoint() throws {
        try state.depart(model: self)
    }
    
    public func arriveAtStop() throws {
        try state.arriveAtStop(model: self)
    }
    
    public func endSeriesReset() throws {
        try state.endSeriesReset(model: self)
    }
    
    public func swapIntervalType() throws {
        try state.swapIntervalType(model: self)
    }
    
    public func resetCurrentIntervalStart() throws {
        try state.resetCurrentIntervalStart(model: self)
    }
    
    public func undoPreviousAction() throws {
        try state.undoPreviousAction(model: self)
    }
    
    func reset() {
        self.timepoints.removeAll()
        self.state = Ready()
        self.startTime = nil
        self.endTime = nil
    }
    
    func stopSeries(at endTime: Date) {
        self.state = StoppedWithData()
        self.endTime = endTime
    }
    
    public init() {}
    
    public var description: String {
        guard !timepoints.isEmpty else {
            return "Empty Interval Series, current state is \(state)"
        }
        return "Interval Series with a total of \(timepoints.count) timepoints from \(timepoints.first!.locationDescription) to \(timepoints.last!.locationDescription), current state is \(state)"
    }
}
