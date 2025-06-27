//
//  Protocol.swift
//  TimingModel
//
//  Created by Trevor Hafner on 6/26/25.
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
