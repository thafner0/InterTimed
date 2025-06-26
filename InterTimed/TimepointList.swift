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
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Start", systemImage: "point.bottomleft.forward.to.arrow.triangle.scurvepath.fill") {
                        withAnimation {
                            try! model.departForNextTimepoint()
                        }
                    }
                    .disabled(!model.state.canDepart)
                    
                    Button("Stop", systemImage: "point.topright.arrow.triangle.backward.to.point.bottomleft.filled.scurvepath") {
                        withAnimation {
                            try! model.arriveAtStop()
                        }
                    }
                    .disabled(!model.state.canArriveAtStop)
                }
                
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            try! model.endSeriesReset()
                        }
                    } label: {
                        if model.state is StoppedWithData {
                            Label("Reset", systemImage: "eraser")
                        } else {
                            Label("End Interval Series", systemImage: "stop.fill")
                        }
                    }
                    .disabled(!model.state.canEndSeriesReset)
                }
                
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Swap Interval Type", systemImage: "rectangle.2.swap") {
                        withAnimation {
                            try! model.swapIntervalType()
                        }
                    }
                    .disabled(!model.state.canSwapIntervalType)
                }
            }
        }
    }
}

#Preview {
    TimepointList()
}
