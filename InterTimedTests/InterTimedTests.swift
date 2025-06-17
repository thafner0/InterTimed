//
//  InterTimedTests.swift
//  InterTimedTests
//
//  Created by Trevor Hafner on 13/06/2025.
//

import Testing
@testable import InterTimed
import Foundation
import RealModule

@MainActor
struct IntervalSeriesModelTests {
    
    @MainActor
    @Suite struct SingleStateTransitionTests {
        
        @MainActor
        @Suite struct FromReadyState {
            let model: IntervalSeriesModel
            
            init() throws {
                self.model = IntervalSeriesModel()
                #expect(model.timepoints == [])
                try model.stateEqual(to: Ready())
            }
            
            @Test func startSeriesWithTravelInterval() async throws {
                let start = Date()
                try model.departForNextTimepoint()
                
                #expect(model.timepoints ~== [
                    Timepoint(name: "Location 1", temporality: .instant(passingAt: start))
                ])
                try model.stateEqual(to: TimingTravel())
            }
            
            @Test func startSeriesWithDwellInterval() async throws {
                let start = Date()
                try model.arriveAtStop()
                
                #expect(model.timepoints == [])
                try model.stateEqual(to: TimingDwell(arrivalTime: start))
            }
            
            @Test func attemptToEndSeriesBeforeStart() async throws {
                #expect(throws: IntervalSeriesModel.ModelError.invalidStateTransition(reason: "Cannot reset timer that's already reset.")) {
                    try model.endSeriesReset()
                }
            }
        }
        
        @MainActor @Suite struct FromTimingTravelState {
            let model: IntervalSeriesModel
            
            init() throws {
                self.model = IntervalSeriesModel()
                let start = Date()
                try model.departForNextTimepoint()
                
                #expect(model.timepoints ~== [
                    Timepoint(name: "Location 1", temporality: .instant(passingAt: start))
                ])
                try model.stateEqual(to: TimingTravel())
            }
            
            @Test func changeTravelIntervalsOverInstantTimepoint() async throws {
                let passMoment = Date()
                let expectedTimepoints = model.timepoints + [
                    Timepoint(name: "Location 2", temporality: .instant(passingAt: passMoment))
                ]
                try model.departForNextTimepoint()
                
                #expect(model.timepoints ~== expectedTimepoints)
                try model.stateEqual(to: TimingTravel())
            }
            
            @Test func collectDwellTime() async throws {
                let arrivalTime = Date()
                let expectedTimepoints = model.timepoints
                try model.arriveAtStop()
                
                #expect(model.timepoints ~== expectedTimepoints)
                try model.stateEqual(to: TimingDwell(arrivalTime: arrivalTime))
            }
            
            @Test func endSeries() async throws {
                let arrivalTime = Date()
                let expectedTimepoints = model.timepoints + [
                    Timepoint(name: "Location 2", temporality: .instant(passingAt: arrivalTime))
                ]
                try model.endSeriesReset()
                
                
                #expect(model.timepoints ~== expectedTimepoints)
                try model.stateEqual(to: StoppedWithData())
            }
        }
        
        @MainActor @Suite struct FromTimingDwellState {
            let model: IntervalSeriesModel
            let originvalState: TimingDwell
            
            init() throws {
                self.model = IntervalSeriesModel()
                
                let arrivalTime = Date()
                try model.arriveAtStop()
                
                #expect(model.timepoints == [])
                try model.stateEqual(to: TimingDwell(arrivalTime: arrivalTime))
                originvalState = TimingDwell(arrivalTime: arrivalTime)
            }
            
            @Test func continueToNextTimepoint() async throws {
                let departureTime = Date()
                let expectedTimepoints = model.timepoints + [
                    Timepoint(name: "Location 1", temporality: .prolonged(arrival: originvalState.arrivalTime, departure: departureTime))
                ]
                try model.departForNextTimepoint()
                
                #expect(model.timepoints ~== expectedTimepoints)
                try model.stateEqual(to: TimingTravel())
            }
            
            @Test func attemptToCollectAdditionalDwellTime() async throws {
                #expect(throws: IntervalSeriesModel.ModelError.invalidStateTransition(reason: "Cannot dwell at two places without traveling between them.")) {
                    try model.arriveAtStop()
                }
            }
            
            @Test func endIntervalSeries() async throws {
                let departureTime = Date()
                let expectedTimepoints = model.timepoints + [
                    Timepoint(name: "Location 1", temporality: .prolonged(arrival: originvalState.arrivalTime, departure: departureTime))
                ]
                try model.endSeriesReset()
                
                #expect(model.timepoints ~== expectedTimepoints)
                try model.stateEqual(to: StoppedWithData())
            }
        }
        
        @MainActor @Suite struct FromStoppedWithDataState {
            let model: IntervalSeriesModel
            
            init() throws {
                self.model = IntervalSeriesModel()
                
                let departureTime = Date()
                try model.departForNextTimepoint()
                
                let arrivalTime = Date()
                try model.endSeriesReset()
                
                #expect(model.timepoints ~== [
                    Timepoint(name: "Location 1", temporality: .instant(passingAt: departureTime)),
                    Timepoint(name: "Location 2", temporality: .instant(passingAt: arrivalTime))
                ])
                try model.stateEqual(to: StoppedWithData())
            }
            
            @Test func attemptToTimeAnotherTravel() async throws {
                #expect(throws: IntervalSeriesModel.ModelError.invalidStateTransition(reason: "Must reset timer before starting new series.")) {
                    try model.departForNextTimepoint()
                }
            }
            
            @Test func attemptToTimeAnotherDwell() async throws {
                #expect(throws: IntervalSeriesModel.ModelError.invalidStateTransition(reason: "Must reset timer before starting new series.")) {
                    try model.arriveAtStop()
                }
            }
            
            @Test func resetToInitialState() async throws {
                try model.endSeriesReset()
                
                #expect(model.timepoints == [])
                try model.stateEqual(to: Ready())
            }
        }
    }
    
    @MainActor @Suite struct IntervalCalculationTests {
        let model = IntervalSeriesModel()
        
        @Test func noTimepoints() throws {
            #expect(model.timepoints.isEmpty)
            #expect(model.intervals.isEmpty)
        }
        
        @Test func singleTimepointWithoutDwell() throws {
            let start = Date()
            try model.departForNextTimepoint()
            #expect(model.timepoints ~== [
                Timepoint(name: "Location 1", temporality: .instant(passingAt: start))
            ])
            #expect(model.intervals == [
                .dwell(duration: nil, locationName: "Location 1")
            ])
        }
        
        @Test func singleTimepointWithDwell() async throws {
            let arrival = Date()
            try model.arriveAtStop()
            try await Task.sleep(for: .milliseconds(10))
            let departure = Date()
            try model.departForNextTimepoint()
            
            #expect(model.timepoints ~== [
                Timepoint(name: "Location 1", temporality: .prolonged(arrival: arrival, departure: departure))
            ])
            #expect(model.intervals ~== [
                .dwell(duration: Duration.seconds(arrival.distance(to: departure)), locationName: "Location 1")
            ])
        }
        
        @Test func manyTimepoints() async throws {
            let departFirst = Date()
            try model.departForNextTimepoint()
            try await Task.sleep(for: .milliseconds(20))
            let arriveSecond = Date()
            try model.arriveAtStop()
            try await Task.sleep(for: .milliseconds(10))
            let departSecond = Date()
            try model.departForNextTimepoint()
            try await Task.sleep(for: .milliseconds(30))
            let arriveDepartThird = Date()
            try model.departForNextTimepoint()
            try await Task.sleep(for: .milliseconds(40))
            let arriveFourth = Date()
            try model.arriveAtStop()
            try await Task.sleep(for: .milliseconds(20))
            let end = Date()
            try model.endSeriesReset()
            
            #expect(model.timepoints ~== [
                Timepoint(name: "Location 1", temporality: .instant(passingAt: departFirst)),
                Timepoint(name: "Location 2", temporality: .prolonged(arrival: arriveSecond, departure: departSecond)),
                Timepoint(name: "Location 3", temporality: .instant(passingAt: arriveDepartThird)),
                Timepoint(name: "Location 4", temporality: .prolonged(arrival: arriveFourth, departure: end))
            ])
            #expect(model.intervals ~== [
                .dwell(duration: nil, locationName: "Location 1"),
                .travel(duration: Duration.seconds(departFirst.distance(to: arriveSecond))),
                .dwell(duration: Duration.seconds(arriveSecond.distance(to: departSecond)), locationName: "Location 2"),
                .travel(duration: Duration.seconds(departSecond.distance(to: arriveDepartThird))),
                .dwell(duration: nil, locationName: "Location 3"),
                .travel(duration: Duration.seconds(arriveDepartThird.distance(to: arriveFourth))),
                .dwell(duration: Duration.seconds(arriveFourth.distance(to: end)), locationName: "Location 4")
            ])
        }
    }
}

infix operator ~==: ComparisonPrecedence
extension Array where Element == Timepoint {
    static func ~== (lhs: Self, rhs: Self) -> Bool {
        guard lhs.count == rhs.count else {
            return false
        }
        let zipped = zip(lhs, rhs)
        
        for (left, right) in zipped {
            guard left.name == right.name else { return false }
            guard left.temporality ~== right.temporality else { return false }
        }
        
        return true
    }
}

extension Array where Element == Interval {
    static func ~== (lhs: Self, rhs: Self) -> Bool {
        guard lhs.count == rhs.count else {
            return false
        }
        let zipped = zip(lhs, rhs)
        
        for (left, right) in zipped {
            guard left ~== right else { return false }
        }
        
        return true
    }
}

extension Temporality {
    static func ~==(_ left: Temporality, _ right: Temporality) -> Bool {
        switch (left, right) {
        case (.instant(passingAt: let leftDate), .instant(passingAt: let rightDate)):
            return leftDate ~== rightDate
        case (.prolonged(arrival: let leftArrival, departure: let leftDeparture), .prolonged(arrival: let rightArrival, departure: let rightDeparture)):
            return leftArrival ~== rightArrival && leftDeparture ~== rightDeparture
        default:
            return false
        }
    }
}

extension Date {
    static func ~==(_ lhs: Date, _ rhs: Date) -> Bool {
        return lhs.timeIntervalSinceReferenceDate.isApproximatelyEqual(to: rhs.timeIntervalSinceReferenceDate, absoluteTolerance: 0.001)
    }
}

extension IntervalSeriesModel {
    func stateEqual<S: IntervalState>(to expected: S) throws {
        let typedState = try #require(self.state as? S)
        if let timingDwellState = typedState as? TimingDwell, let expectedTimingDwellState = expected as? TimingDwell {
            #expect(timingDwellState.arrivalTime ~== expectedTimingDwellState.arrivalTime)
        }
    }
}

extension Interval {
    static func ~==(_ lhs: Interval, _ rhs: Interval) -> Bool {
        func norm(_ duration: Duration) -> Double {
            return Double(duration.attoseconds) * Double.pow(10, -15)
        }
        
        switch (lhs, rhs) {
        case (.dwell(duration: let leftDuration, locationName: let leftName), .dwell(duration: let rightDuration, locationName: let rightName)):
            guard let leftDuration, let rightDuration else {
                guard case .none = leftDuration, case .none = rightDuration else {
                    return false
                }
                return leftName == rightName
            }
            let durationsEqual = leftDuration.isApproximatelyEqual(to: rightDuration, absoluteTolerance: 1, norm: norm(_:))
            return durationsEqual && leftName == rightName
        case (.travel(duration: let leftDuration), .travel(duration: let rightDuration)):
            return leftDuration.isApproximatelyEqual(to: rightDuration, absoluteTolerance: 1, norm: norm(_:))
        default:
            return false
        }
    }
}
