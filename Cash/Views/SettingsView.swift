//
//  SettingsView.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    var showWelcome: Binding<Bool>?
    var isErasing: Binding<Bool>?
    var dismissSettings: Binding<Bool>?
    @State private var showingFirstResetAlert = false
    @State private var showingSecondResetAlert = false
    @State private var showingExportFormatPicker = false
    @State private var showingImportConfirmation = false
    @State private var showingImportFilePicker = false
    @State private var showingExportSuccess = false
    @State private var showingImportSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var importResult: (accountsCount: Int, transactionsCount: Int) = (0, 0)
    @State private var showingLocalWelcome = false
    
    @Query private var accounts: [Account]
    @Query private var transactions: [Transaction]
    
    var body: some View {
        @Bindable var settings = settings
        
        Form {
            Section {
                Picker("Theme", selection: $settings.theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Label(theme.localizedName, systemImage: theme.iconName)
                            .tag(theme)
                    }
                }
                .pickerStyle(.inline)
            } header: {
                Label("Appearance", systemImage: "paintbrush.fill")
            } footer: {
                Text("Choose how Cash looks. System follows your macOS appearance settings.")
            }
            
            Section {
                Picker("Language", selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Label(language.localizedName, systemImage: language.iconName)
                            .tag(language)
                    }
                }
                .pickerStyle(.inline)
            } header: {
                Label("Language", systemImage: "globe")
            }
            
            Section {
                Button {
                    showingExportFormatPicker = true
                } label: {
                    Label("Export data", systemImage: "square.and.arrow.up")
                }
                
                Button {
                    showingImportConfirmation = true
                } label: {
                    Label("Import data", systemImage: "square.and.arrow.down")
                }
            } header: {
                Label("Export / Import", systemImage: "arrow.up.arrow.down.circle.fill")
            } footer: {
                Text("Export your data as JSON (full backup) or CSV (for spreadsheets). Import will replace all existing data.")
            }
            
            Section {
                Button(role: .destructive) {
                    showingFirstResetAlert = true
                } label: {
                    Label("Reset all data", systemImage: "trash.fill")
                }
            } header: {
                Label("Data", systemImage: "externaldrive.fill")
            } footer: {
                Text("This will delete all accounts and transactions.")
            }
            
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label("About", systemImage: "info.circle.fill")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .id(settings.refreshID)
        .alert("Reset all data?", isPresented: $showingFirstResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Continue", role: .destructive) {
                showingSecondResetAlert = true
            }
        } message: {
            Text("This will permanently delete all your accounts and transactions. This action cannot be undone.")
        }
        .alert("Are you absolutely sure?", isPresented: $showingSecondResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete everything", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("All data will be permanently deleted.")
        }
        .sheet(isPresented: $showingLocalWelcome) {
            LocalWelcomeView(
                modelContext: modelContext,
                isPresented: $showingLocalWelcome
            )
            .environment(settings)
        }
        .sheet(isPresented: $showingExportFormatPicker) {
            ExportFormatPickerView { format in
                exportData(format: format)
            }
        }
        .alert("Import data?", isPresented: $showingImportConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Continue") {
                showingImportFilePicker = true
            }
        } message: {
            Text("Importing will replace all existing data. Make sure to export your current data first if needed.")
        }
        .fileImporter(
            isPresented: $showingImportFilePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
        .alert("Export successful", isPresented: $showingExportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your data has been exported successfully.")
        }
        .alert("Import successful", isPresented: $showingImportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Imported \(importResult.accountsCount) accounts and \(importResult.transactionsCount) transactions.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Export
    
    private func exportData(format: ExportFormat) {
        do {
            let data: Data
            
            switch format {
            case .json:
                data = try DataExporter.exportJSON(accounts: accounts, transactions: transactions)
            case .csv:
                data = try DataExporter.exportCSV(transactions: transactions)
            }
            
            let filename = DataExporter.generateFilename(for: format)
            
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [format.utType]
            savePanel.nameFieldStringValue = filename
            savePanel.canCreateDirectories = true
            
            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    do {
                        try data.write(to: url)
                        showingExportSuccess = true
                    } catch {
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    // MARK: - Import
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                // Start accessing security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    throw DataExporterError.importFailed("Cannot access file")
                }
                defer { url.stopAccessingSecurityScopedResource() }
                
                let data = try Data(contentsOf: url)
                
                // Delete existing data first (safely)
                deleteAllData()
                
                // Import new data
                let result = try DataExporter.importJSON(from: data, into: modelContext)
                importResult = result
                showingImportSuccess = true
                
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func deleteAllData() {
        // Fetch and delete each type individually to avoid crashes on empty stores
        let attachments = (try? modelContext.fetch(FetchDescriptor<Attachment>())) ?? []
        for attachment in attachments { modelContext.delete(attachment) }
        
        let rules = (try? modelContext.fetch(FetchDescriptor<RecurrenceRule>())) ?? []
        for rule in rules { modelContext.delete(rule) }
        
        let entries = (try? modelContext.fetch(FetchDescriptor<Entry>())) ?? []
        for entry in entries { modelContext.delete(entry) }
        
        let transactions = (try? modelContext.fetch(FetchDescriptor<Transaction>())) ?? []
        for transaction in transactions { modelContext.delete(transaction) }
        
        let accounts = (try? modelContext.fetch(FetchDescriptor<Account>())) ?? []
        for account in accounts { modelContext.delete(account) }
    }
    
    // MARK: - Reset
    
    private func resetAllData() {
        // Close settings sheet immediately
        dismissSettings?.wrappedValue = false
        
        // Use external binding if available
        if let isErasing = isErasing {
            isErasing.wrappedValue = true
            
            Task.detached(priority: .userInitiated) {
                // Small delay to let the sheet dismiss
                try? await Task.sleep(nanoseconds: 300_000_000)
                
                await MainActor.run {
                    // Delete all data using the safe method
                    deleteAllData()
                    
                    do {
                        try modelContext.save()
                    } catch {
                        print("Error saving after delete: \(error)")
                    }
                    
                    // Also delete the SwiftData store file to ensure complete reset
                    deleteSwiftDataStore()
                    
                    // Reset first launch flag
                    UserDefaults.standard.removeObject(forKey: "hasCompletedSetup")
                    
                    isErasing.wrappedValue = false
                    
                    // Show welcome dialog
                    if let showWelcome = showWelcome {
                        showWelcome.wrappedValue = true
                    }
                }
            }
        } else {
            // Fallback for when opened from Settings menu (no external bindings)
            deleteAllData()
            
            do {
                try modelContext.save()
            } catch {
                print("Error saving after delete: \(error)")
            }
            
            deleteSwiftDataStore()
            UserDefaults.standard.removeObject(forKey: "hasCompletedSetup")
            showingLocalWelcome = true
        }
    }
    
    private func deleteSwiftDataStore() {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        
        // SwiftData default store location
        let storeURL = appSupport.appendingPathComponent("default.store")
        let storeShmURL = appSupport.appendingPathComponent("default.store-shm")
        let storeWalURL = appSupport.appendingPathComponent("default.store-wal")
        
        for url in [storeURL, storeShmURL, storeWalURL] {
            try? fileManager.removeItem(at: url)
        }
    }
}

// MARK: - Export Format Picker

struct ExportFormatPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (ExportFormat) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose export format")
                .font(.headline)
            
            Text("JSON is recommended for full backup and restore. CSV is useful for viewing in spreadsheets.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                ForEach(ExportFormat.allCases) { format in
                    Button {
                        dismiss()
                        onSelect(format)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: format.iconName)
                                .font(.largeTitle)
                            Text(format.localizedName)
                                .font(.headline)
                            Text(format == .json ? "Full backup" : "Spreadsheet")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 120, height: 100)
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.plain)
        }
        .padding(30)
        .frame(width: 340)
    }
}

// MARK: - Local Welcome View (for Settings menu)

struct LocalWelcomeView: View {
    let modelContext: ModelContext
    @Binding var isPresented: Bool
    @State private var showingImportFilePicker = false
    @State private var showingImportError = false
    @State private var importErrorMessage = ""
    @State private var isImporting = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.tint)
                
                Text("Welcome to Cash")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Choose how to start:")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 12) {
                    Button {
                        showingImportFilePicker = true
                    } label: {
                        Label("Import existing data", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isImporting)
                    
                    Button {
                        createDefaultAccounts()
                        markAsCompleted()
                        isPresented = false
                    } label: {
                        Label("Create example accounts", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isImporting)
                    
                    Button {
                        markAsCompleted()
                        isPresented = false
                    } label: {
                        Label("Start empty", systemImage: "doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isImporting)
                }
                .frame(width: 250)
            }
            .padding(40)
            .disabled(isImporting)
            
            if isImporting {
                Color.black.opacity(0.3)
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(.circular)
                    
                    Text("Importing data...")
                        .font(.headline)
                }
                .padding(30)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .frame(width: 350)
        .fileImporter(
            isPresented: $showingImportFilePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
        .alert("Import error", isPresented: $showingImportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importErrorMessage)
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
            
            Task.detached(priority: .userInitiated) {
                do {
                    let data = try Data(contentsOf: url)
                    url.stopAccessingSecurityScopedResource()
                    
                    await MainActor.run {
                        do {
                            _ = try DataExporter.importJSON(from: data, into: modelContext)
                            markAsCompleted()
                            isImporting = false
                            isPresented = false
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

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AppSettings.shared)
}
