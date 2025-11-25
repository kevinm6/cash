//
//  AddTransactionView.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Account.name) private var accounts: [Account]
    
    var preselectedAccount: Account?
    
    @State private var transactionType: TransactionType = .expense
    @State private var date: Date = Date()
    @State private var descriptionText: String = ""
    @State private var selectedCategory: String = ""
    @State private var categorySearchText: String = ""
    @State private var amountText: String = ""
    @State private var selectedAccount: Account?
    
    @State private var isRecurring: Bool = false
    @State private var frequency: RecurrenceFrequency = .monthly
    @State private var dayOfMonth: Int = 1
    @State private var selectedWeekDay: WeekDay = .monday
    @State private var weekendHandling: WeekendHandling = .none
    @State private var startDate: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date().addingTimeInterval(365 * 24 * 60 * 60)
    
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    
    private var filteredCategories: [CategoryInfo] {
        let categories = CategoryList.categories(for: transactionType)
        if categorySearchText.isEmpty {
            return categories
        }
        return categories.filter { $0.name.localizedCaseInsensitiveContains(categorySearchText) }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Transaction Type")) {
                    Picker(String(localized: "Type"), selection: $transactionType) {
                        ForEach(TransactionType.allCases) { type in
                            Label(type.localizedName, systemImage: type.iconName)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: transactionType) {
                        selectedCategory = ""
                        categorySearchText = ""
                    }
                }
                
                Section(String(localized: "Account")) {
                    if accounts.isEmpty {
                        Text("No accounts available. Please create an account first.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker(String(localized: "Account"), selection: $selectedAccount) {
                            Text(String(localized: "Select Account")).tag(nil as Account?)
                            ForEach(accounts) { account in
                                Label(account.name, systemImage: account.accountType.iconName)
                                    .tag(account as Account?)
                            }
                        }
                    }
                }
                
                Section(String(localized: "Details")) {
                    if !isRecurring {
                        DatePicker(String(localized: "Date"), selection: $date, displayedComponents: .date)
                    }
                    
                    TextField(String(localized: "Description"), text: $descriptionText)
                    
                    TextField(String(localized: "Amount"), text: $amountText)
                        .help(String(localized: "Enter the transaction amount"))
                }
                
                Section(String(localized: "Category")) {
                    TextField(String(localized: "Search or select category"), text: $categorySearchText)
                    
                    List(filteredCategories) { category in
                        Button {
                            selectedCategory = category.name
                            categorySearchText = category.name
                        } label: {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundStyle(transactionType == .income ? .green : .red)
                                    .frame(width: 24)
                                Text(category.name)
                                Spacer()
                                if selectedCategory == category.name {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(minHeight: 150)
                }
                
                Section {
                    Toggle(String(localized: "Make this recurring"), isOn: $isRecurring)
                        .onChange(of: isRecurring) {
                            if isRecurring {
                                startDate = date
                            }
                        }
                }
                
                if isRecurring {
                    RecurringFieldsView(
                        frequency: $frequency,
                        dayOfMonth: $dayOfMonth,
                        selectedWeekDay: $selectedWeekDay,
                        weekendHandling: $weekendHandling,
                        startDate: $startDate,
                        hasEndDate: $hasEndDate,
                        endDate: $endDate
                    )
                }
            }
            .formStyle(.grouped)
            .navigationTitle(String(localized: "New Transaction"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        saveTransaction()
                    }
                    .disabled(selectedAccount == nil || amountText.isEmpty)
                }
            }
            .alert(String(localized: "Validation Error"), isPresented: $showingValidationError) {
                Button(String(localized: "OK"), role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .onAppear {
                if let preselectedAccount {
                    selectedAccount = preselectedAccount
                }
            }
        }
        .frame(minWidth: 450, minHeight: 600)
    }
    
    private func saveTransaction() {
        guard let account = selectedAccount else {
            validationMessage = String(localized: "Please select an account.")
            showingValidationError = true
            return
        }
        
        let cleanedAmount = amountText.replacingOccurrences(of: ",", with: ".")
        guard let amount = Decimal(string: cleanedAmount), amount > 0 else {
            validationMessage = String(localized: "Please enter a valid positive amount.")
            showingValidationError = true
            return
        }
        
        let category = selectedCategory.isEmpty ? 
            (transactionType == .expense ? String(localized: "Other Expense") : String(localized: "Other Income")) : 
            selectedCategory
        
        if isRecurring {
            let recurring = RecurringTransaction(
                descriptionText: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
                category: category,
                amount: amount,
                transactionType: transactionType,
                frequency: frequency,
                dayOfMonth: frequency == .monthly ? dayOfMonth : nil,
                weekDay: frequency == .weekly ? selectedWeekDay : nil,
                weekendHandling: weekendHandling,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                account: account
            )
            
            modelContext.insert(recurring)
        } else {
            let transaction = Transaction(
                date: date,
                descriptionText: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
                category: category,
                amount: amount,
                transactionType: transactionType,
                account: account
            )
            
            modelContext.insert(transaction)
            
            // Update account balance
            account.balance += transaction.signedAmount
        }
        
        dismiss()
    }
}

#Preview {
    AddTransactionView()
        .modelContainer(for: Account.self, inMemory: true)
}
