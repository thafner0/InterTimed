//
//  TimepointList.swift
//  InterTimed
//
//  Created by Trevor Hafner on 13/06/2025.
//

import SwiftUI
import TimingModel
import OSLog

struct TimepointList: View {
    @State var model = IntervalSeries()
    
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
                            do {
                                try model.departForNextTimepoint()
                            } catch {
                                if let lastTimepoint = model.timepoints.last {
                                    log.fault("Error when initiating leg from \(lastTimepoint.locationDescription, privacy: .private(mask: .hash)) in the \(model.state.description, privacy: .public) state: \(error, privacy: .public)")
                                } else {
                                    log.fault("Error when initiating leg from start location in the \(model.state.description, privacy: .public) state: \(error, privacy: .public)")
                                }
                            }
                        }
                    }
                    .disabled(!model.state.canDepart)
                    
                    Button("Stop", systemImage: "point.topright.arrow.triangle.backward.to.point.bottomleft.filled.scurvepath") {
                        withAnimation {
                            do {
                                try model.arriveAtStop()
                            } catch {
                                if let lastTimepoint = model.timepoints.last {
                                    log.fault("Error when initiating dwell at \(lastTimepoint.locationDescription, privacy: .private(mask: .hash)) in the \(model.state.description, privacy: .public) state: \(error, privacy: .public)")
                                } else {
                                    log.fault("Error when initiating dwell at start location in the \(model.state.description, privacy: .public) state: \(error, privacy: .public)")
                                }
                            }
                        }
                    }
                    .disabled(!model.state.canArriveAtStop)
                }
                
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            do {
                                try model.endSeriesReset()
                            } catch {
                                log.fault("Error when stopping/resetting series in the \(model.state.description, privacy: .public) state: \(error)")
                            }
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
                            do {
                                try model.swapIntervalType()
                            } catch {
                                if let lastTimepoint = model.timepoints.last {
                                    log.fault("Error when swapping interval type in the \(model.state.description, privacy: .public) state: \(error); (Last timepoint: \(lastTimepoint.locationDescription, privacy: .private(mask: .hash)))")
                                } else {
                                    log.fault("Error when swapping interval type in the \(model.state.description, privacy: .public) state: \(error); (no timepoints)")
                                }
                            }
                        }
                    }
                    .disabled(!model.state.isTiming)
                    
                    Button("Restart Current Interval", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90") {
                        withAnimation {
                            do {
                                try model.resetCurrentIntervalStart()
                            } catch {
                                if let lastTimepoint = model.timepoints.last {
                                    log.fault("Error when restarting current interval in the \(model.state.description, privacy: .public) state: \(error); (Last timepoint: \(lastTimepoint.locationDescription, privacy: .private(mask: .hash)))")
                                } else {
                                    log.fault("Error when restarting current interval in the \(model.state.description, privacy: .public) state: \(error); (no timepoints)")
                                }
                            }
                        }
                    }
                    .disabled(!model.state.isTiming)
                    
                    Button("Undo Previous Action", systemImage: "arrow.uturn.backward") {
                        withAnimation {
                            do {
                                try model.undoPreviousAction()
                            } catch {
                                if let lastTimepoint = model.timepoints.last {
                                    log.fault("Error when undoing previous action in the \(model.state.description, privacy: .public) state: \(error); (Last timepoint: \(lastTimepoint.locationDescription, privacy: .private(mask: .hash)))")
                                } else {
                                    log.fault("Error when undoing previous action in the \(model.state.description, privacy: .public) state: \(error); (no timepoints)")
                                }
                            }
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
