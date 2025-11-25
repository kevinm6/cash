//
//  RecurringTransactionListView.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import SwiftUI
import SwiftData

struct RecurringTransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecurringTransaction.descriptionText) private var recurringTransactions: [RecurringTransaction]
    @State private var recurringToEdit: RecurringTransaction?
    @State private var recurringToDelete: RecurringTransaction?
    
    var body: some View {
        Group {
            if recurringTransactions.isEmpty {
                ContentUnavailableView {
                    Label(String(localized: "No Recurring Transactions"), systemImage: "repeat")
                } description: {
                    Text("Create recurring transactions by enabling 'Make this recurring' when adding a transaction.")
                }
            } else {
                List {
                    ForEach(recurringTransactions) { recurring in
                        RecurringTransactionRowView(recurring: recurring)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                recurringToEdit = recurring
                            }
                            .contextMenu {
                                Button {
                                    recurringToEdit = recurring
                                } label: {
                                    Label(String(localized: "Edit"), systemImage: "pencil")
                                }
                                
                                Button {
                                    toggleActive(recurring)
                                } label: {
                                    Label(
                                        recurring.isActive ? String(localized: "Deactivate") : String(localized: "Activate"),
                                        systemImage: recurring.isActive ? "pause.circle" : "play.circle"
                                    )
                                }
                                
                                Button(role: .destructive) {
                                    recurringToDelete = recurring
                                } label: {
                                    Label(String(localized: "Delete"), systemImage: "trash")
                                }
                            }
                    }
                    .onDelete(perform: deleteRecurring)
                }
            }
        }
        .navigationTitle(String(localized: "Recurring Transactions"))
        .sheet(item: $recurringToEdit) { recurring in
            EditRecurringTransactionView(recurring: recurring)
        }
        .confirmationDialog(
            String(localized: "Delete Recurring Transaction"),
            isPresented: Binding(
                get: { recurringToDelete != nil },
                set: { if !$0 { recurringToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(String(localized: "Delete"), role: .destructive) {
                if let recurring = recurringToDelete {
                    modelContext.delete(recurring)
                }
            }
            Button(String(localized: "Cancel"), role: .cancel) {
                recurringToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this recurring transaction?")
        }
    }
    
    private func toggleActive(_ recurring: RecurringTransaction) {
        recurring.isActive.toggle()
    }
    
    private func deleteRecurring(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(recurringTransactions[index])
        }
    }
}

struct RecurringTransactionRowView: View {
    let recurring: RecurringTransaction
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: CategoryList.icon(for: recurring.category))
                .font(.title2)
                .foregroundColor(recurring.transactionType == .income ? .green : .red)
                .opacity(recurring.isActive ? 1.0 : 0.5)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(recurring.descriptionText.isEmpty ? recurring.category : recurring.descriptionText)
                        .font(.headline)
                    
                    if !recurring.isActive {
                        Text(String(localized: "Paused"))
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                
                HStack(spacing: 4) {
                    Text(recurring.frequency.localizedName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(scheduleDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let account = recurring.account {
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
            
            Text(formatAmount(recurring))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(recurring.transactionType == .income ? .green : .red)
                .opacity(recurring.isActive ? 1.0 : 0.5)
        }
        .padding(.vertical, 4)
    }
    
    private var scheduleDescription: String {
        switch recurring.frequency {
        case .daily:
            return String(localized: "Every day")
        case .weekly:
            if let weekDay = recurring.weekDay {
                return String(localized: "Every \(weekDay.localizedName)")
            }
            return ""
        case .monthly:
            if let day = recurring.dayOfMonth {
                return String(localized: "Day \(day)")
            }
            return ""
        }
    }
    
    private func formatAmount(_ recurring: RecurringTransaction) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = recurring.account?.currency ?? "EUR"
        let prefix = recurring.transactionType == .income ? "+" : "-"
        let formatted = formatter.string(from: recurring.amount as NSDecimalNumber) ?? "\(recurring.amount)"
        return "\(prefix)\(formatted)"
    }
}

#Preview {
    NavigationStack {
        RecurringTransactionListView()
    }
    .modelContainer(for: Account.self, inMemory: true)
}
