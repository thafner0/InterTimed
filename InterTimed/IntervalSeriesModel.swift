//
//  IntervalSeriesModel.swift
//  InterTimed
//
//  Created by Trevor Hafner on 13/06/2025.
//

import Foundation

class IntervalSeriesModel {
    var timepoints: [TimingPoint] = []
    var intervals: [Interval] = []
    var startOfIntervalInProgress: IntervalType?
    private var nextTimepoint = 1
    
    func startIntervalSeries() throws {
        guard timepoints.isEmpty && intervals.isEmpty else {
            throw UnsupportedOperationError.cannotStartSeriesWithData
        }
        
        startTravelInterval()
        timepoints.append(TimingPoint(name: "Location 2"))
        nextTimepoint += 1
    }
    
    func endIntervalSeries() throws {
        try endTravelInterval()
    }
    
    func endTravelInterval(skippingDwellTime: Bool) throws {
        try endTravelInterval()
        if skippingDwellTime {
            startTravelInterval()
        } else {
            startOfIntervalInProgress = .dwell(start: Date())
        }
    }
    
    func endDwellInterval() throws {
        guard case .dwell(_) = startOfIntervalInProgress else {
            throw UnsupportedOperationError.noDwellInterval
        }
        startTravelInterval(endingDwell: true)
    }
    
    private func startTravelInterval(endingDwell: Bool = false) {
        let start = Date()
        if endingDwell {
            timepoints[timepoints.index(before: timepoints.endIndex)].dwellDuration = Duration.seconds(intervals.last!.arrivalTime.distance(to: start))
        }
        startOfIntervalInProgress = .travel(start: start)
        timepoints.append(TimingPoint(name: "Location \(nextTimepoint)"))
        nextTimepoint += 1
    }
    
    private func endTravelInterval() throws {
        let end = Date()
        guard case .travel(let start) = startOfIntervalInProgress else {
            throw UnsupportedOperationError.cannotEndIntervalWhenNotRunning
        }
        intervals.append(Interval(departureTime: start, arrivalTime: end))
    }
    
    enum UnsupportedOperationError: Error {
        case cannotStartSeriesWithData
        case cannotEndIntervalWhenNotRunning
        case noDwellInterval
    }
    
    enum IntervalType: Equatable {
        case travel(start: Date)
        case dwell(start: Date)
        
        var start: Date {
            switch self {
            case .travel(start: let start), .dwell(start: let start):
                return start
            }
        }
    }
}
