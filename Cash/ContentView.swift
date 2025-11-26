//
//  ContentView.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Query private var accounts: [Account]
    @State private var showingSettings = false
    @State private var showingWelcome = false
    @State private var showingImportFilePicker = false
    @State private var showingImportError = false
    @State private var importErrorMessage = ""
    @State private var isImporting = false
    @State private var isErasing = false
    
    private var isFirstLaunch: Bool {
        !UserDefaults.standard.bool(forKey: "hasCompletedSetup")
    }
    
    var body: some View {
        AccountListView()
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView(
                        showWelcome: $showingWelcome,
                        isErasing: $isErasing,
                        dismissSettings: $showingSettings
                    )
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showingSettings = false
                                }
                            }
                        }
                }
                .frame(minWidth: 450, minHeight: 400)
                .environment(settings)
                .environment(\.locale, settings.language.locale)
            }
            .alert("Welcome to Cash", isPresented: $showingWelcome) {
                Button("Import existing data") {
                    showingImportFilePicker = true
                }
                Button("Create example accounts") {
                    createDefaultAccounts()
                    markAsCompleted()
                }
                Button("Start empty", role: .cancel) {
                    markAsCompleted()
                }
            } message: {
                Text("Cash helps you manage your personal finances using double-entry bookkeeping.\n\nEvery transaction has two sides: money comes from somewhere and goes somewhere else.")
            }
            .fileImporter(
                isPresented: $showingImportFilePicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .alert("Import error", isPresented: $showingImportError) {
                Button("OK", role: .cancel) {
                    showingWelcome = true
                }
            } message: {
                Text(importErrorMessage)
            }
            .overlay {
                if isImporting {
                    LoadingOverlayView(message: String(localized: "Importing data..."))
                } else if isErasing {
                    LoadingOverlayView(message: String(localized: "Erasing data..."))
                }
            }
            .task {
                if isFirstLaunch {
                    showingWelcome = true
                }
            }
    }
    
    private func createDefaultAccounts() {
        let defaultAccounts = ChartOfAccounts.createDefaultAccounts(currency: "EUR")
        for account in defaultAccounts {
            modelContext.insert(account)
        }
    }
    
    private func markAsCompleted() {
        UserDefaults.standard.set(true, forKey: "hasCompletedSetup")
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            guard url.startAccessingSecurityScopedResource() else {
                importErrorMessage = DataExporterError.importFailed("Cannot access file").localizedDescription
                showingImportError = true
                return
            }
            
            isImporting = true
            
            // Read data on background thread
            Task.detached(priority: .userInitiated) {
                do {
                    let data = try Data(contentsOf: url)
                    url.stopAccessingSecurityScopedResource()
                    
                    // Import on main thread (SwiftData requires main context)
                    await MainActor.run {
                        do {
                            _ = try DataExporter.importJSON(from: data, into: modelContext)
                            markAsCompleted()
                            isImporting = false
                        } catch {
                            importErrorMessage = error.localizedDescription
                            isImporting = false
                            showingImportError = true
                        }
                    }
                } catch {
                    url.stopAccessingSecurityScopedResource()
                    await MainActor.run {
                        importErrorMessage = error.localizedDescription
                        isImporting = false
                        showingImportError = true
                    }
                }
            }
            
        case .failure(let error):
            importErrorMessage = error.localizedDescription
            showingImportError = true
        }
    }
}

// MARK: - Loading Overlay

struct LoadingOverlayView: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(.circular)
                
                Text(message)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(30)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Account.self, inMemory: true)
        .environment(AppSettings.shared)
}
