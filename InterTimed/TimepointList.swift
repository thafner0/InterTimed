//
//  TimepointList.swift
//  InterTimed
//
//  Created by Trevor Hafner on 13/06/2025.
//

import SwiftUI
import TimingModel

struct TimepointList: View {
    @State var model = IntervalSeriesModel()
    @Namespace var animation
    
    var stopButtonSymbolName: String {
        if model.state is StoppedWithData {
            return "eraser"
        } else {
            return "stop.fill"
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(model.timepoints.legs.reversed()) { leg in
                    TimepointCell(timepoint: leg.end)
                    LegCell(leg: leg)
                }
                if let first = model.timepoints.first {
                    TimepointCell(timepoint: first)
                }
            }
            .navigationTitle("Intervals")
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button("Start", systemImage: "point.bottomleft.forward.to.arrow.triangle.scurvepath.fill") {
                    withAnimation {
                        try! model.departForNextTimepoint()
                    }
                }
                .disabled(!model.state.canDepart)
            }
            
            ToolbarItem(placement: .bottomBar) {
                Button("Stop", systemImage: "point.topright.arrow.triangle.backward.to.point.bottomleft.filled.scurvepath") {
                    withAnimation {
                        try! model.arriveAtStop()
                    }
                }
                .disabled(!model.state.canArriveAtStop)
            }
            
            ToolbarSpacer(.fixed, placement: .bottomBar)
            
            ToolbarItem(placement: .bottomBar) {
                Button("Stop", systemImage: stopButtonSymbolName) {
                    withAnimation {
                        try! model.endSeriesReset()
                    }
                }
                .disabled(!model.state.canEndSeriesReset)
            }
        }
    }
}

#Preview {
    TimepointList()
}
