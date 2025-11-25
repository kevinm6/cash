//
//  AccountListView.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import SwiftUI
import SwiftData

struct AccountListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.name) private var accounts: [Account]
    @State private var showingAddAccount = false
    @State private var selectedAccount: Account?
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedAccount) {
                if accounts.isEmpty {
                    ContentUnavailableView {
                        Label(String(localized: "No Accounts"), systemImage: "building.columns")
                    } description: {
                        Text("Create your first account to get started.")
                    } actions: {
                        Button(String(localized: "Add Account")) {
                            showingAddAccount = true
                        }
                    }
                } else {
                    ForEach(AccountType.allCases) { accountType in
                        let filteredAccounts = accounts.filter { $0.accountType == accountType }
                        if !filteredAccounts.isEmpty {
                            Section(accountType.localizedName) {
                                ForEach(filteredAccounts) { account in
                                    AccountRowView(account: account)
                                        .tag(account)
                                }
                                .onDelete { indexSet in
                                    deleteAccounts(from: filteredAccounts, at: indexSet)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "Accounts"))
            .navigationSplitViewColumnWidth(min: 250, ideal: 300)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddAccount = true }) {
                        Label(String(localized: "Add Account"), systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView()
            }
        } detail: {
            if let account = selectedAccount {
                AccountDetailView(account: account)
            } else {
                ContentUnavailableView {
                    Label(String(localized: "Select an Account"), systemImage: "building.columns")
                } description: {
                    Text("Choose an account from the sidebar to view details.")
                }
            }
        }
    }
    
    private func deleteAccounts(from filteredAccounts: [Account], at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let account = filteredAccounts[index]
                modelContext.delete(account)
            }
        }
    }
}

struct AccountRowView: View {
    let account: Account
    
    var body: some View {
        HStack {
            Image(systemName: account.accountType.iconName)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.headline)
                Text(account.accountNumber)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(formatBalance(account.balance, currency: account.currency))
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
    
    private func formatBalance(_ balance: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: balance as NSDecimalNumber) ?? "\(CurrencyList.symbol(forCode: currency))\(balance)"
    }
}

#Preview {
    AccountListView()
        .modelContainer(for: Account.self, inMemory: true)
}
