//
//  AccountDetailView.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import SwiftUI
import SwiftData

struct AccountDetailView: View {
    @Bindable var account: Account
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingAddTransaction = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Card
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: account.accountType.iconName)
                        .font(.title)
                        .foregroundStyle(.tint)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(account.accountType.localizedName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(formatBalance(account.balance, currency: account.currency))
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(account.balance >= 0 ? .primary : .red)
                }
                
                HStack(spacing: 16) {
                    DetailPill(label: String(localized: "Account Number"), value: account.accountNumber.isEmpty ? "-" : account.accountNumber)
                    DetailPill(label: String(localized: "Currency"), value: account.currency)
                }
            }
            .padding()
            .background(.regularMaterial)
            
            Divider()
            
            // Transactions List
            TransactionListView(account: account)
        }
        .navigationTitle(account.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddTransaction = true }) {
                    Label(String(localized: "Add Transaction"), systemImage: "plus")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button(action: { showingEditSheet = true }) {
                    Label(String(localized: "Edit Account"), systemImage: "pencil")
                }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                    Label(String(localized: "Delete"), systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditAccountView(account: account)
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView(preselectedAccount: account)
        }
        .confirmationDialog(
            String(localized: "Delete Account"),
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Delete"), role: .destructive) {
                modelContext.delete(account)
            }
            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this account? This action cannot be undone.")
        }
    }
    
    private func formatBalance(_ balance: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: balance as NSDecimalNumber) ?? "\(CurrencyList.symbol(forCode: currency))\(balance)"
    }
}

struct DetailPill: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    @Previewable @State var account = Account(
        name: "Main Checking",
        accountNumber: "1234567890",
        currency: "EUR",
        accountType: .bank,
        balance: 5432.10
    )
    
    NavigationStack {
        AccountDetailView(account: account)
    }
    .modelContainer(for: Account.self, inMemory: true)
}
