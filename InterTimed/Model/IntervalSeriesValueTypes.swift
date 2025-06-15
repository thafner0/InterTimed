//
//  IntervalSeriesValueTypes.swift
//  InterTimed
//
//  Created by Trevor Hafner on 14/06/2025.
//

import Foundation

struct TimingPoint: Equatable {
    var name: String
    var dwellDuration: Duration? = nil
}

struct Interval: Equatable {
    let departureTime: Date
    let arrivalTime: Date
    var duration: Duration {
        let interval = departureTime.distance(to: arrivalTime)
        return Duration.seconds(interval)
    }
}
