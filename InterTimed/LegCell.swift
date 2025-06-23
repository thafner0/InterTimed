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
            Text(leg.end.temporality.arrivalTime, format: .stopwatch(startingAt: leg.start.temporality.departureTime))
        }
    }
}

#Preview {
    List(0..<10) { _ in
        LegCell(leg: .random)
    }
}
