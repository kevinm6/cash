//
//  ContentView.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showingSettings = false
    
    var body: some View {
        AccountListView()
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingSettings = true }) {
                        Label(String(localized: "Settings"), systemImage: "gear")
                    }
                    .keyboardShortcut(",", modifiers: .command)
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button(String(localized: "Done")) {
                                    showingSettings = false
                                }
                            }
                        }
                }
                .frame(minWidth: 450, minHeight: 400)
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Account.self, inMemory: true)
        .environment(AppSettings.shared)
}
