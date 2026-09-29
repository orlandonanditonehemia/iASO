//
//  iASOApp.swift
//  iASO
//
//  Created by profitfirst on 03/05/26.
//

import SwiftUI

@main
struct iASOApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 960, height: 640)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
