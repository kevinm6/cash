//
//  TransactionListView.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @State private var showingAddTransaction = false
    @State private var transactionToEdit: Transaction?
    @State private var transactionToDelete: Transaction?
    
    var account: Account?
    
    private var filteredTransactions: [Transaction] {
        if let account {
            return transactions.filter { $0.account?.id == account.id }
        }
        return transactions
    }
    
    private var groupedTransactions: [(String, [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            transaction.date.formatted(date: .long, time: .omitted)
        }
        return grouped.sorted { $0.value.first?.date ?? Date() > $1.value.first?.date ?? Date() }
    }
    
    var body: some View {
        Group {
            if filteredTransactions.isEmpty {
                ContentUnavailableView {
                    Label(String(localized: "No Transactions"), systemImage: "arrow.left.arrow.right")
                } description: {
                    Text("Add your first transaction to track your finances.")
                } actions: {
                    Button(String(localized: "Add Transaction")) {
                        showingAddTransaction = true
                    }
                }
            } else {
                List {
                    ForEach(groupedTransactions, id: \.0) { dateString, dayTransactions in
                        Section(dateString) {
                            ForEach(dayTransactions) { transaction in
                                TransactionRowView(transaction: transaction, showAccount: account == nil)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        transactionToEdit = transaction
                                    }
                                    .contextMenu {
                                        Button {
                                            transactionToEdit = transaction
                                        } label: {
                                            Label(String(localized: "Edit"), systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive) {
                                            transactionToDelete = transaction
                                        } label: {
                                            Label(String(localized: "Delete"), systemImage: "trash")
                                        }
                                    }
                            }
                            .onDelete { indexSet in
                                deleteTransactions(from: dayTransactions, at: indexSet)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(account?.name ?? String(localized: "All Transactions"))
        .toolbar {
            if account == nil {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddTransaction = true }) {
                        Label(String(localized: "Add Transaction"), systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView(preselectedAccount: account)
        }
        .sheet(item: $transactionToEdit) { transaction in
            EditTransactionView(transaction: transaction)
        }
        .confirmationDialog(
            String(localized: "Delete Transaction"),
            isPresented: Binding(
                get: { transactionToDelete != nil },
                set: { if !$0 { transactionToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(String(localized: "Delete"), role: .destructive) {
                if let transaction = transactionToDelete {
                    deleteTransaction(transaction)
                }
            }
            Button(String(localized: "Cancel"), role: .cancel) {
                transactionToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this transaction?")
        }
    }
    
    private func deleteTransactions(from dayTransactions: [Transaction], at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let transaction = dayTransactions[index]
                deleteTransaction(transaction)
            }
        }
    }
    
    private func deleteTransaction(_ transaction: Transaction) {
        withAnimation {
            if let account = transaction.account {
                account.balance -= transaction.signedAmount
            }
            modelContext.delete(transaction)
        }
    }
}

struct TransactionRowView: View {
    let transaction: Transaction
    var showAccount: Bool = true
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: CategoryList.icon(for: transaction.category))
                .font(.title2)
                .foregroundColor(transaction.transactionType == .income ? .green : .red)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.descriptionText.isEmpty ? transaction.category : transaction.descriptionText)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Text(transaction.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if showAccount, let account = transaction.account {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(account.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Text(formatAmount(transaction))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(transaction.transactionType == .income ? .green : .red)
        }
        .padding(.vertical, 4)
    }
    
    private func formatAmount(_ transaction: Transaction) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = transaction.account?.currency ?? "EUR"
        let prefix = transaction.transactionType == .income ? "+" : "-"
        let formatted = formatter.string(from: transaction.amount as NSDecimalNumber) ?? "\(transaction.amount)"
        return "\(prefix)\(formatted)"
    }
}

#Preview {
    NavigationStack {
        TransactionListView()
    }
    .modelContainer(for: Account.self, inMemory: true)
}
