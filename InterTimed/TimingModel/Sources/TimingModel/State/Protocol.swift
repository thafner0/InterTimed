//
//  Protocol.swift
//  TimingModel
//
//  Created by Trevor Hafner on 6/26/25.
//

import Foundation

public protocol IntervalState: Equatable, CustomStringConvertible {
    var canDepart: Bool { get }
    var canArriveAtStop: Bool { get }
    var canEndSeriesReset: Bool { get }
    var isTiming: Bool { get }
    var canUndo: Bool { get }
    
    func depart(model: IntervalSeries) throws
    func arriveAtStop(model: IntervalSeries) throws
    func endSeriesReset(model: IntervalSeries) throws
    func swapIntervalType(model: IntervalSeries) throws
    func resetCurrentIntervalStart(model: IntervalSeries) throws
    func undoPreviousAction(model: IntervalSeries) throws
}
