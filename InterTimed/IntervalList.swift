//
//  IntervalList.swift
//  InterTimed
//
//  Created by Trevor Hafner on 13/06/2025.
//

import SwiftUI

struct IntervalList: View {
    @Bindable var model = IntervalSeriesModel()
    
    var stopButtonSymbolName: String {
        if model.state is StoppedWithData {
            return "eraser"
        } else {
            return "stop.fill"
        }
    }
    
    var body: some View {
        NavigationStack {
            List(model.intervals) { interval in
                IntervalListRow(interval: interval)
            }
            .navigationTitle("Intervals")
        }
        .toolbar {
            if model.state.canDepart {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("Start", systemImage: "point.bottomleft.forward.to.arrow.triangle.scurvepath.fill") {
                        try! model.departForNextTimepoint()
                    }
                    
                    Button("Stop", systemImage: "point.topright.arrow.triangle.backward.to.point.bottomleft.filled.scurvepath") {
                        try! model.arriveAtStop()
                    }
                    .disabled(!model.state.canArriveAtStop)
                }
            }
            
            ToolbarSpacer(.fixed, placement: .bottomBar)
            
            if model.state.canEndSeriesReset {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("Stop", systemImage: stopButtonSymbolName) {
                        try! model.endSeriesReset()
                    }
                }
            }
        }
    }
}

#Preview {
    IntervalList()
}
