//
//  SettingsView.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @State private var showingRestartAlert = false
    @State private var showingCategories = false
    @State private var showingRecurring = false
    
    var body: some View {
        @Bindable var settings = settings
        
        Form {
            Section {
                Picker(String(localized: "Theme"), selection: $settings.theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Label(theme.localizedName, systemImage: theme.iconName)
                            .tag(theme)
                    }
                }
                .pickerStyle(.inline)
            } header: {
                Label(String(localized: "Appearance"), systemImage: "paintbrush.fill")
            } footer: {
                Text("Choose how Cash looks. System follows your macOS appearance settings.")
            }
            
            Section {
                Picker(String(localized: "Language"), selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Label(language.localizedName, systemImage: language.iconName)
                            .tag(language)
                    }
                }
                .pickerStyle(.inline)
                .onChange(of: settings.language) {
                    showingRestartAlert = true
                }
            } header: {
                Label(String(localized: "Language"), systemImage: "globe")
            } footer: {
                Text("Language changes require restarting the app to take full effect.")
            }
            
            Section {
                Button(action: { showingCategories = true }) {
                    HStack {
                        Label(String(localized: "Manage Categories"), systemImage: "tag")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                
                Button(action: { showingRecurring = true }) {
                    HStack {
                        Label(String(localized: "Recurring Transactions"), systemImage: "repeat")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Label(String(localized: "Data"), systemImage: "folder.fill")
            }
            
            Section {
                HStack {
                    Text(String(localized: "Version"))
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label(String(localized: "About"), systemImage: "info.circle.fill")
            }
        }
        .formStyle(.grouped)
        .navigationTitle(String(localized: "Settings"))
        .alert(String(localized: "Restart Required"), isPresented: $showingRestartAlert) {
            Button(String(localized: "OK"), role: .cancel) { }
        } message: {
            Text("Please restart the app for the language change to take effect.")
        }
        .sheet(isPresented: $showingCategories) {
            NavigationStack {
                CategoryListView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(String(localized: "Done")) {
                                showingCategories = false
                            }
                        }
                    }
            }
            .frame(minWidth: 500, minHeight: 500)
        }
        .sheet(isPresented: $showingRecurring) {
            NavigationStack {
                RecurringTransactionListView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(String(localized: "Done")) {
                                showingRecurring = false
                            }
                        }
                    }
            }
            .frame(minWidth: 600, minHeight: 500)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AppSettings.shared)
}
