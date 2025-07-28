//
//  TimepointList.swift
//  InterTimed
//
//  Created by Trevor Hafner on 13/06/2025.
//

import SwiftUI
import TimingModel

struct TimepointList: View {
    @State var model = IntervalSeries()
    
    @ViewBuilder
    private var totalTimeDescription: some View {
        if let first = model.timepoints.first {
            if model.state is StoppedWithData {
                Text(model.timepoints.last!.temporality.arrivalTime!, format: .stopwatch(startingAt: first.temporality.departureTime!))
            } else {
                Text(TimeDataSource<Date>.currentDate, format: .stopwatch(startingAt: first.temporality.departureTime!))
            }
        } else {
            Text("---")
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("General Statistics")) {
                    LabeledContent("Total Time") {
                        totalTimeDescription
                    }
                    LabeledContent("Number of Timepoints") {
                        Text(model.timepoints.count, format: .number)
                            .contentTransition(.numericText())
                    }
                }
                
                Section(header: Text("Individual Intervals")) {
                    ForEach(model.timepoints.legs.reversed()) { leg in
                        TimepointCell(timepoint: leg.end)
                        LegCell(leg: leg)
                    }
                    if let first = model.timepoints.first {
                        TimepointCell(timepoint: first)
                    }
                }
            }
            .navigationTitle("Interval Series")
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
                    .disabled(!model.state.isTiming)
                    
                    Button("Restart Current Interval", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90") {
                        withAnimation {
                            try! model.resetCurrentIntervalStart()
                        }
                    }
                    .disabled(!model.state.isTiming)
                    
                    Button("Undo Previous Action", systemImage: "arrow.uturn.backward") {
                        withAnimation {
                            try! model.undoPreviousAction()
                        }
                    }
                    .disabled(!model.state.canUndo)
                }
            }
        }
    }
}

#Preview {
    TimepointList()
}
