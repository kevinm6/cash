//
//  AccountListView.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import SwiftUI
import SwiftData

enum SidebarSelection: Hashable {
    case patrimony
    case forecast
    case budget
    case loans
    case reports
    case scheduled
    case account(Account)
}

struct AccountListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Environment(NavigationState.self) private var navigationState
    @Query(sort: \Account.accountNumber) private var accounts: [Account]
    @Query(filter: #Predicate<Transaction> { $0.isRecurring == true }) private var scheduledTransactions: [Transaction]
    @State private var showingAddAccount = false
    @State private var showingAddTransaction = false
    @State private var selection: SidebarSelection? = .patrimony
    
    private var hasAccounts: Bool {
        !accounts.filter { $0.isActive && !$0.isSystem }.isEmpty
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                if accounts.isEmpty {
                    ContentUnavailableView {
                        Label("No accounts", systemImage: "building.columns")
                    } description: {
                        Text("Create your first account to get started.")
                    }
                } else {
                    if hasAccounts {
                        Section {
                            Label("Net Worth", systemImage: "chart.pie.fill")
                                .tag(SidebarSelection.patrimony)
                            
                            Label("Forecast", systemImage: "chart.line.uptrend.xyaxis")
                                .tag(SidebarSelection.forecast)
                            
                            Label("Budget", systemImage: "envelope.fill")
                                .tag(SidebarSelection.budget)
                            
                            Label("Loans & Mortgages", systemImage: "house.fill")
                                .tag(SidebarSelection.loans)
                            
                            Label("Reports", systemImage: "chart.bar.fill")
                                .tag(SidebarSelection.reports)
                        }
                    }
                    
                    ForEach(AccountClass.allCases.sorted(by: { $0.displayOrder < $1.displayOrder })) { accountClass in
                        let classAccounts = accounts
                            .filter { $0.accountClass == accountClass && $0.isActive && !$0.isSystem }
                        
                        if !classAccounts.isEmpty {
                            Section(accountClass.localizedPluralName) {
                                // Add Scheduled as first item in Expenses section
                                if accountClass == .expense {
                                    HStack {
                                        Label("Scheduled", systemImage: "calendar.badge.clock")
                                        Spacer()
                                        if !scheduledTransactions.isEmpty {
                                            Text("\(scheduledTransactions.count)")
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(.quaternary)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    .tag(SidebarSelection.scheduled)
                                }
                                
                                // Group accounts by type within each class
                                let accountTypes = Array(Set(classAccounts.map { $0.accountType }))
                                    .sorted { $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending }
                                
                                ForEach(accountTypes, id: \.self) { accountType in
                                    let typeAccounts = classAccounts
                                        .filter { $0.accountType == accountType }
                                        .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
                                    
                                    if typeAccounts.count == 1 {
                                        // Single account of this type - show directly
                                        ForEach(typeAccounts) { account in
                                            AccountRowView(account: account)
                                                .tag(SidebarSelection.account(account))
                                        }
                                        .onDelete { indexSet in
                                            deleteAccounts(from: typeAccounts, at: indexSet)
                                        }
                                    } else {
                                        // Multiple accounts - show type header then accounts
                                        AccountTypeHeaderView(
                                            accountType: accountType,
                                            accounts: typeAccounts
                                        )
                                        
                                        ForEach(typeAccounts) { account in
                                            AccountRowView(account: account, indented: true)
                                                .tag(SidebarSelection.account(account))
                                        }
                                        .onDelete { indexSet in
                                            deleteAccounts(from: typeAccounts, at: indexSet)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Chart of accounts")
            .navigationSplitViewColumnWidth(min: 280, ideal: 320)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            settings.privacyMode.toggle()
                        }
                    } label: {
                        Label(
                            settings.privacyMode ? "Show amounts" : "Hide amounts",
                            systemImage: settings.privacyMode ? "eye.slash.fill" : "eye.fill"
                        )
                    }
                    .help(settings.privacyMode ? "Show amounts" : "Hide amounts")
                    
                    Button(action: { showingAddAccount = true }) {
                        Label("Add account", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView()
            }
            .id(settings.refreshID)
        } detail: {
            Group {
                switch selection {
                case .patrimony:
                    NetWorthView()
                case .forecast:
                    ForecastView()
                case .budget:
                    BudgetView()
                case .loans:
                    LoansView()
                case .reports:
                    ReportsView()
                case .scheduled:
                    ScheduledTransactionsView()
                case .account(let account):
                    AccountDetailView(account: account, showingAddTransaction: $showingAddTransaction)
                case nil:
                    ContentUnavailableView {
                        Label("Select an account", systemImage: "building.columns")
                    } description: {
                        Text("Choose an account from the sidebar to view details")
                    }
                }
            }
        }
        .onChange(of: selection) { _, newValue in
            switch newValue {
            case .account(let account):
                navigationState.isViewingAccount = true
                navigationState.isViewingScheduled = false
                navigationState.currentAccount = account
            case .scheduled:
                navigationState.isViewingAccount = false
                navigationState.isViewingScheduled = true
                navigationState.currentAccount = nil
            default:
                navigationState.isViewingAccount = false
                navigationState.isViewingScheduled = false
                navigationState.currentAccount = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .addNewAccount)) { _ in
            showingAddAccount = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .addNewTransaction)) { _ in
            if navigationState.isViewingAccount {
                showingAddTransaction = true
            }
        }
    }
    
    private func deleteAccounts(from filteredAccounts: [Account], at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let account = filteredAccounts[index]
                if !account.isSystem {
                    modelContext.delete(account)
                }
            }
        }
    }
}

struct AccountRowView: View {
    @Environment(AppSettings.self) private var settings
    let account: Account
    var indented: Bool = false
    
    var body: some View {
        HStack {
            if indented {
                Spacer()
                    .frame(width: 16)
            }
            
            Image(systemName: account.accountType.iconName)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(account.displayName)
                        .font(indented ? .subheadline : .headline)
                    if account.isSystem {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            PrivacyAmountView(
                amount: CurrencyFormatter.format(account.balance, currency: account.currency),
                isPrivate: settings.privacyMode,
                font: .subheadline,
                fontWeight: .medium,
                color: balanceColor(for: account)
            )
        }
        .padding(.vertical, 4)
    }
    
    private func balanceColor(for account: Account) -> Color {
        if account.balance == 0 {
            return .secondary
        }
        switch account.accountClass {
        case .asset:
            return account.balance >= 0 ? .primary : .red
        case .liability:
            return .primary
        case .income:
            return .green
        case .expense:
            return .red
        case .equity:
            return .primary
        }
    }
}

// MARK: - Account Type Header View

struct AccountTypeHeaderView: View {
    @Environment(AppSettings.self) private var settings
    let accountType: AccountType
    let accounts: [Account]
    
    private var totalBalance: Decimal {
        accounts.reduce(Decimal.zero) { $0 + $1.balance }
    }
    
    private var currency: String {
        accounts.first?.currency ?? "EUR"
    }
    
    var body: some View {
        HStack {
            Image(systemName: accountType.iconName)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            Text(accountType.localizedName)
                .font(.headline)
            
            Text("(\(accounts.count))")
                .font(.caption)
                .foregroundStyle(.tertiary)
            
            Spacer()
            
            PrivacyAmountView(
                amount: CurrencyFormatter.format(totalBalance, currency: currency),
                isPrivate: settings.privacyMode,
                font: .subheadline,
                fontWeight: .medium,
                color: .secondary
            )
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AccountListView()
        .modelContainer(for: [Account.self, Transaction.self], inMemory: true)
        .environment(AppSettings.shared)
        .environment(NavigationState())
}
