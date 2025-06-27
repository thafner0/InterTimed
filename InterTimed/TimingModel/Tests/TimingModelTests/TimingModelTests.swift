import Testing
@testable import TimingModel
import Foundation
import RealModule

@MainActor
@Suite struct SingleStateTransitionTests {
    
    @MainActor
    @Suite struct FromReadyState {
        let model: IntervalSeries
        
        init() throws {
            self.model = IntervalSeries()
            #expect(model.timepoints == [])
            try model.stateEqual(to: Ready())
        }
        
        @Test func startSeriesWithTravelInterval() async throws {
            let start = Date()
            try model.departForNextTimepoint()
            
            #expect(model.timepoints ~== [
                Timepoint(name: "Location1", temporality: .start(departureTime: start)),
                Timepoint(name: "Location2", temporality: .awaitingArrival)
            ])
            try model.stateEqual(to: TimingLeg())
        }
        
        @Test func startSeriesWithDwellInterval() async throws {
            let start = Date()
            try model.arriveAtStop()
            
            #expect(model.timepoints ~== [
                Timepoint(name: "Location1", temporality: .awaitingDeparture(afterArrival: start))
            ])
            try model.stateEqual(to: TimingDwell(arrivalTime: start))
        }
        
        @Test func attemptToEndSeriesBeforeStart() async throws {
            #expect(throws: ImproperStateTransition.cannotResetAlreadyResetTimer) {
                try model.endSeriesReset()
            }
        }
    }
    
    @MainActor @Suite struct FromTimingTravelState {
        let model: IntervalSeries
        
        init() throws {
            self.model = IntervalSeries()
            let start = Date()
            try model.departForNextTimepoint()
            
            #expect(model.timepoints ~== [
                Timepoint(name: "Location1", temporality: .start(departureTime: start)),
                Timepoint(name: "Location2", temporality: .awaitingArrival)
            ])
            try model.stateEqual(to: TimingLeg())
        }
        
        @Test func changeTravelIntervalsOverInstantTimepoint() async throws {
            let passMoment = Date()
            let expectedTimepoints = Array(model.timepoints.dropLast() + [
                Timepoint(name: "Location2", temporality: .pass(at: passMoment)),
                Timepoint(name: "Location3", temporality: .awaitingArrival)
            ])
            try model.departForNextTimepoint()
            
            #expect(model.timepoints ~== expectedTimepoints)
            try model.stateEqual(to: TimingLeg())
        }
        
        @Test func collectDwellTime() async throws {
            let arrivalTime = Date()
            let expectedTimepoints = Array(model.timepoints.dropLast() + [
                Timepoint(name: "Location2", temporality: .awaitingDeparture(afterArrival: arrivalTime))
            ])
            try model.arriveAtStop()
            
            #expect(model.timepoints ~== expectedTimepoints)
            try model.stateEqual(to: TimingDwell(arrivalTime: arrivalTime))
        }
        
        @Test func endSeries() async throws {
            let arrivalTime = Date()
            let expectedTimepoints = Array(model.timepoints.dropLast() + [
                Timepoint(name: "Location2", temporality: .end(arrivalTime: arrivalTime))
            ])
            try model.endSeriesReset()
            
            
            #expect(model.timepoints ~== expectedTimepoints)
            try model.stateEqual(to: StoppedWithData())
        }
    }
    
    @MainActor @Suite struct FromTimingDwellState {
        let model: IntervalSeries
        let originalState: TimingDwell
        
        init() throws {
            self.model = IntervalSeries()
            
            let arrivalTime = Date()
            try model.arriveAtStop()
            
            #expect(model.timepoints ~== [
                Timepoint(name: "Location1", temporality: .awaitingDeparture(afterArrival: arrivalTime))
            ])
            try model.stateEqual(to: TimingDwell(arrivalTime: arrivalTime))
            originalState = TimingDwell(arrivalTime: arrivalTime)
        }
        
        @Test func continueToNextTimepoint() async throws {
            let departureTime = Date()
            let expectedTimepoints = [
                Timepoint(name: "Location1", temporality: .prolonged(arrival: originalState.arrivalTime, departure: departureTime)),
                Timepoint(name: "Location2", temporality: .awaitingArrival)
            ]
            try model.departForNextTimepoint()
            
            #expect(model.timepoints ~== expectedTimepoints)
            try model.stateEqual(to: TimingLeg())
        }
        
        @Test func attemptToCollectAdditionalDwellTime() async throws {
            #expect(throws: ImproperStateTransition.immediatelySuccessiveDwellsNotPermitted) {
                try model.arriveAtStop()
            }
        }
        
        @Test func endIntervalSeries() async throws {
            let departureTime = Date()
            let expectedTimepoints = [
                Timepoint(name: "Location1", temporality: .prolonged(arrival: originalState.arrivalTime, departure: departureTime))
            ]
            try model.endSeriesReset()
            
            #expect(model.timepoints ~== expectedTimepoints)
            try model.stateEqual(to: StoppedWithData())
        }
    }
    
    @MainActor @Suite struct FromStoppedWithDataState {
        let model: IntervalSeries
        
        init() throws {
            self.model = IntervalSeries()
            
            let departureTime = Date()
            try model.departForNextTimepoint()
            
            let arrivalTime = Date()
            try model.endSeriesReset()
            
            #expect(model.timepoints ~== [
                Timepoint(name: "Location1", temporality: .start(departureTime: departureTime)),
                Timepoint(name: "Location2", temporality: .end(arrivalTime: arrivalTime))
            ])
            try model.stateEqual(to: StoppedWithData())
        }
        
        @Test func attemptToTimeAnotherTravel() async throws {
            #expect(throws: ImproperStateTransition.mustResetTimerBeforeStartingAgain) {
                try model.departForNextTimepoint()
            }
        }
        
        @Test func attemptToTimeAnotherDwell() async throws {
            #expect(throws: ImproperStateTransition.mustResetTimerBeforeStartingAgain) {
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

infix operator ~==: ComparisonPrecedence
extension Collection where Element == Timepoint {
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

extension Optional where Wrapped == Date {
    static func ~==(_ left: Self, _ right: Self) -> Bool {
        switch (left, right) {
        case (.none, .none):
            return true
        case (.some(let left), .some(let right)):
            return left ~== right
        default:
            return false
        }
    }
}

extension Timepoint.Temporality {
    static func ~==(_ left: Timepoint.Temporality, _ right: Timepoint.Temporality) -> Bool {
        guard left.arrivalTime ~== right.arrivalTime && left.departureTime ~== right.departureTime else {
            return false
        }
        
        switch (left, right) {
        case (.start(departureTime: _), .start(departureTime: _)), (.pass(at: _), .pass(at: _)), (.prolonged(arrival: _, departure: _), .prolonged(arrival: _, departure: _)), (.awaitingArrival, .awaitingArrival), (.awaitingDeparture(afterArrival: _), .awaitingDeparture(afterArrival: _)), (.end(arrivalTime:), .end(arrivalTime: _)):
            return true
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

extension IntervalSeries {
    func stateEqual<S: IntervalState>(to expected: S) throws {
        let typedState = try #require(self.state as? S)
        if let timingDwellState = typedState as? TimingDwell, let expectedTimingDwellState = expected as? TimingDwell {
            #expect(timingDwellState.arrivalTime ~== expectedTimingDwellState.arrivalTime)
        }
    }
}
