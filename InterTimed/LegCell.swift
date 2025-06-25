//
//  LegCell.swift
//  InterTimed
//
//  Created by Trevor Hafner on 6/23/25.
//

import SwiftUI
import TimingModel

struct LegCell: View {
    let leg: Leg
    
    var body: some View {
        HStack {
            Image(systemName: "arrow.up")
            Spacer()
            if let departureTime = leg.start.temporality.departureTime {
                if let arrivalTime = leg.end.temporality.arrivalTime {
                    Text(arrivalTime, format: .stopwatch(startingAt: departureTime))
                } else {
                    Text(TimeDataSource<Date>.currentDate, format: .stopwatch(startingAt: departureTime))
                }
            }
        }
    }
}

#Preview {
    List(0..<10) { _ in
        LegCell(leg: .random)
    }
}
