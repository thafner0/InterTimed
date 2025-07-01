//
//  InterTimedApp.swift
//  InterTimed
//
//  Created by Trevor Hafner on 13/06/2025.
//

import SwiftUI
import OSLog

@main
struct InterTimedApp: App {
    var body: some Scene {
        WindowGroup {
            TimepointList()
        }
    }
}

let log = Logger(subsystem: "com.TrevorHafner.InterTimed", category: "User Interface")
