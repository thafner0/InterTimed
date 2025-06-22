//
//  IntervalList.swift
//  InterTimed
//
//  Created by Trevor Hafner on 13/06/2025.
//

import SwiftUI

struct IntervalList: View {
    @Bindable var model = IntervalSeriesModel()
    
    var body: some View {
        NavigationStack {
            List(model.intervals) { interval in
                IntervalListRow(interval: interval)
            }
            .navigationTitle("Intervals")
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button("Start", systemImage: "point.bottomleft.forward.to.arrow.triangle.scurvepath.fill") {
                    try! model.departForNextTimepoint()
                }
                .disabled(!model.state.canDepart)
                
                Button("Stop", systemImage: "point.topright.arrow.triangle.backward.to.point.bottomleft.filled.scurvepath") {
                    try! model.arriveAtStop()
                }
                .disabled(!model.state.canArriveAtStop)
            }
            
            ToolbarSpacer(placement: .bottomBar)
            
            ToolbarItemGroup(placement: .bottomBar) {
                Button("Stop", systemImage: "stop.fill") {
                    try! model.endSeriesReset()
                }
                .disabled(!model.state.canEndSeriesReset)
            }
        }
    }
}

#Preview {
    IntervalList()
}
