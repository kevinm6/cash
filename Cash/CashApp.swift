//
//  CashApp.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import SwiftUI
import SwiftData

// MARK: - Navigation State

@Observable
class NavigationState {
    var isViewingAccount: Bool = false
    var isViewingScheduled: Bool = false
    var currentAccount: Account? = nil
}

// MARK: - Cmd+N Notifications

extension Notification.Name {
    static let addNewAccount = Notification.Name("addNewAccount")
    static let addNewTransaction = Notification.Name("addNewTransaction")
    static let addNewScheduledTransaction = Notification.Name("addNewScheduledTransaction")
    static let importOFX = Notification.Name("importOFX")
    static let showSubscription = Notification.Name("showSubscription")
    static let showSubscriptionTab = Notification.Name("showSubscriptionTab")
}

@main
struct CashApp: App {
    @State private var settings = AppSettings.shared
    @State private var menuAppState = AppState()
    @State private var navigationState = NavigationState()
    @State private var showingSubscriptionSheet = false
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Account.self,
            Transaction.self,
            Entry.self,
            Attachment.self,
            RecurrenceRule.self,
            AppConfiguration.self,
            Budget.self,
            Envelope.self,
            Loan.self,
        ])
        
        #if ENABLE_ICLOUD
        let cloudManager = CloudKitManager.shared
        
        // Try CloudKit if enabled and available
        if cloudManager.isEnabled && cloudManager.isAvailable {
            do {
                let cloudConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .private(cloudManager.containerIdentifier)
                )
                return try ModelContainer(for: schema, configurations: [cloudConfig])
            } catch {
                // CloudKit failed, fall back to local storage
                print("CloudKit initialization failed: \(error). Falling back to local storage.")
            }
        }
        #endif
        
        // Local storage (default)
        let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [localConfig])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(navigationState)
        }
        .modelContainer(sharedModelContainer)
        .environment(settings)
        .commands {
            // Replace default New Window command with contextual actions
            CommandGroup(replacing: .newItem) {
                Button {
                    if navigationState.isViewingAccount {
                        NotificationCenter.default.post(name: .addNewTransaction, object: nil)
                    } else if navigationState.isViewingScheduled {
                        NotificationCenter.default.post(name: .addNewScheduledTransaction, object: nil)
                    } else {
                        NotificationCenter.default.post(name: .addNewAccount, object: nil)
                    }
                } label: {
                    if navigationState.isViewingAccount {
                        Text("New transaction")
                    } else if navigationState.isViewingScheduled {
                        Text("New scheduled transaction")
                    } else {
                        Text("New account")
                    }
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            // Import menu
            CommandGroup(replacing: .importExport) {
                Button {
                    NotificationCenter.default.post(name: .importOFX, object: nil)
                } label: {
                    Label("Import OFX...", systemImage: "doc.badge.arrow.up")
                }
            }
            
            // Subscription menu item in App menu
            CommandGroup(after: .appSettings) {
                Button {
                    showingSubscriptionSheet = true
                } label: {
                    Label("Subscription...", systemImage: "crown.fill")
                }
            }
        }
        
        Settings {
            SettingsView(appState: menuAppState, dismissSettings: {})
                .environment(settings)
                .modelContainer(sharedModelContainer)
                .overlay {
                    if menuAppState.isLoading {
                        LoadingOverlayView(message: menuAppState.loadingMessage)
                    }
                }
                .sheet(isPresented: $menuAppState.showWelcomeSheet) {
                    WelcomeSheet(appState: menuAppState)
                        .modelContainer(sharedModelContainer)
                        .interactiveDismissDisabled()
                }
                .sheet(isPresented: $showingSubscriptionSheet) {
                    SubscriptionSheetView()
                }
        }
    }
}

// MARK: - Subscription Sheet View

struct SubscriptionSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            HStack {
                Text("Subscription")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
            .padding()
            
            Divider()
            
            // Content
            SubscriptionSettingsTab()
        }
        .frame(width: 500, height: 450)
    }
}
