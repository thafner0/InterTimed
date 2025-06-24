//
//  TimepointCell.swift
//  InterTimed
//
//  Created by Trevor Hafner on 6/23/25.
//

import SwiftUI
import TimingModel
import Foundation

struct TimepointCell: View {
    @Bindable var timepoint: Timepoint
    
    var body: some View {
        HStack {
            TextField("Station, Point of Interest, Landmark, etc", text: $timepoint.name)
            Spacer()
            switch timepoint.temporality {
            case .instant(passingAt: _):
                Text("Skipped")
                    .italic()
            case .prolonged(arrival: let arrival, departure: let departure):
                Text(departure, format: .stopwatch(startingAt: arrival))
            case .awaitingDeparture(afterArrival: let arrival):
                Text(TimeDataSource<Date>.currentDate, format: .stopwatch(startingAt: arrival))
            case .awaitingArrival:
                EmptyView()
            }
        }
    }
    
    init(timepoint: Timepoint) {
        self.timepoint = timepoint
    }
}

#Preview {
    List(0..<20) { _ in
        TimepointCell(timepoint: .random)
    }
}
