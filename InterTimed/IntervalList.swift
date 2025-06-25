//
//  IntervalList.swift
//  InterTimed
//
//  Created by Trevor Hafner on 13/06/2025.
//

import SwiftUI
import TimingModel

struct IntervalList: View {
    @State var model = IntervalSeriesModel()
    
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
                ToolbarItem(placement: .bottomBar) {
                    Button("Start", systemImage: "point.bottomleft.forward.to.arrow.triangle.scurvepath.fill") {
                        try! model.departForNextTimepoint()
                    }
                }
            }
            
            if model.state.canArriveAtStop {
                ToolbarItem(placement: .bottomBar) {
                    Button("Stop", systemImage: "point.topright.arrow.triangle.backward.to.point.bottomleft.filled.scurvepath") {
                        try! model.arriveAtStop()
                    }
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
