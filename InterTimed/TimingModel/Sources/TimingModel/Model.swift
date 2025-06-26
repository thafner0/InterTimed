//
//  IntervalSeriesModel.swift
//  TimingModel
//
//  Created by Trevor Hafner on 6/15/25.
//

import Foundation

@Observable
public class IntervalSeriesModel {
    public internal(set) var timepoints: [Timepoint] = []
    
    public internal(set) var state: any IntervalState = Ready()
    
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
    
    public init() {}
}
