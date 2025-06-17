//
//  IntervalListRow.swift
//  InterTimed
//
//  Created by Trevor Hafner on 6/16/25.
//

import SwiftUI

struct IntervalListRow: View {
    let interval: Interval
    
    private static var format = Duration.TimeFormatStyle(pattern: .minuteSecond(padMinuteToLength: 2, fractionalSecondsLength: 2))
    
    var body: some View {
        HStack {
            switch interval.type {
            case .dwell(duration: let duration, locationName: let locationName):
                Text(locationName)
                Spacer()
                if let duration {
                    Text(duration.formatted(Self.format))
                } else {
                    Text("Skipped")
                        .italic()
                }
            case .travel(duration: let duration):
                Image(systemName: "arrow.down")
                Spacer()
                Text(duration.formatted(Self.format))
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    let intervals = {
        var intervals = [Interval]()
        intervals.append(Interval(type: .dwell(duration: Duration.seconds(Double.random(in: 0...300)), locationName: "Location 1"), id: 0))
        for id in 1..<10 {
            intervals.append(Interval(type: .travel(duration: Duration.seconds(Double.random(in: 0...1800))), id: -id))
            intervals.append(Interval(type: .dwell(duration: Duration.seconds(Double.random(in: 0...300)), locationName: "Location \(id + 1)"), id: id))
        }
        return intervals
    }()
    
    List(intervals) { interval in
        IntervalListRow(interval: interval)
    }
}
