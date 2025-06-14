//
//  InterTimedTests.swift
//  InterTimedTests
//
//  Created by Trevor Hafner on 13/06/2025.
//

import Testing
@testable import InterTimed
import Foundation

@MainActor
struct IntervalSeriesModelTests {
    let model: IntervalSeriesModel
    let units = Set([Calendar.Component.hour, .minute, .second])

    init() {
        self.model = IntervalSeriesModel()
    }
    
    func datesEqualWithinSecond(_ first: Date, _ second: Date) -> Bool {
        let firstDateComponents = Calendar.current.dateComponents(units, from: first)
        let secondDateComponents = Calendar.current.dateComponents(units, from: second)
        return firstDateComponents == secondDateComponents
    }
    
    @Test func successfulStart() async throws {
        let start = Date()
        try model.startIntervalSeries()
        
        #expect(model.timepoints == [
            TimingPoint(name: "Location 1"),
            TimingPoint(name: "Location 2")
        ])
        #expect(model.intervals.isEmpty)
        let intervalInProgress = try #require(model.startOfIntervalInProgress)
        #expect(datesEqualWithinSecond(start, intervalInProgress.start))
    }

    @Test func endIntervalSkipDwell() async throws {
        let start = Date()
        try model.startIntervalSeries()
        try await Task.sleep(nanoseconds: 2_000_000_000)
        let end = Date()
        try model.endTravelInterval(skippingDwellTime: true)
        
        #expect(model.timepoints == [
            TimingPoint(name: "Location 1"),
            TimingPoint(name: "Location 2"),
            TimingPoint(name: "Location 3")
        ])
        #expect(model.intervals.count == 1)
        #expect(datesEqualWithinSecond(start, model.intervals[0].departureTime))
        #expect(datesEqualWithinSecond(end, model.intervals[0].arrivalTime))
        
        let intervalInProgress = try #require(model.startOfIntervalInProgress)
        if case .travel(start: _) = intervalInProgress {} else {
            Issue.record("Invalid interval type: expected .travel, got \(intervalInProgress).")
        }
        #expect(datesEqualWithinSecond(intervalInProgress.start, end))
    }
    
    @Test func endIntervalNoSkipDwell() async throws {
        let start = Date()
        try model.startIntervalSeries()
        try await Task.sleep(nanoseconds: 2_000_000_000)
        let end = Date()
        try model.endTravelInterval(skippingDwellTime: false)
        
        #expect(model.timepoints == [
            TimingPoint(name: "Location 1"),
            TimingPoint(name: "Location 2")
        ])
        #expect(model.intervals.count == 1)
        #expect(datesEqualWithinSecond(model.intervals[0].departureTime, start))
        #expect(datesEqualWithinSecond(model.intervals[0].arrivalTime, end))
        
        let intervalInProgress = try #require(model.startOfIntervalInProgress)
        if case .dwell(start: _) = intervalInProgress {} else {
            Issue.record("Invalid interval type: expected .dwell, got \(intervalInProgress).")
        }
        #expect(datesEqualWithinSecond(intervalInProgress.start, end))
    }
    
    @Test func endDwell() async throws {
        let start = Date()
        try model.startIntervalSeries()
        try await Task.sleep(nanoseconds: 2_000_000_000)
        let startDwell = Date()
        try model.endTravelInterval(skippingDwellTime: false)
        try await Task.sleep(nanoseconds: 2_000_000_000)
        let endDwell = Date()
        try model.endDwellInterval()
        
        #expect(model.timepoints.count == 3)
        #expect(model.timepoints[0] == TimingPoint(name: "Location 1"))
        #expect(model.timepoints[2] == TimingPoint(name: "Location 3"))
        #expect(model.timepoints[1].name == "Location 2")
        #expect(model.timepoints[1].dwellDuration?.components.seconds == 2)
        
        #expect(model.intervals.count == 1)
        #expect(datesEqualWithinSecond(model.intervals[0].departureTime, start))
        #expect(datesEqualWithinSecond(model.intervals[0].arrivalTime, startDwell))
        
        let intervalInProgress = try #require(model.startOfIntervalInProgress)
        if case .travel(start: _) = intervalInProgress {} else {
            Issue.record("Invalid interval type: expected .travel, got \(intervalInProgress).")
        }
        #expect(datesEqualWithinSecond(intervalInProgress.start, endDwell))
        
    }
}
