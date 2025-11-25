//
//  EditTransactionView.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import SwiftUI
import SwiftData

struct EditTransactionView: View {
    @Bindable var transaction: Transaction
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Account.name) private var accounts: [Account]
    
    @State private var transactionType: TransactionType = .expense
    @State private var date: Date = Date()
    @State private var descriptionText: String = ""
    @State private var selectedCategory: String = ""
    @State private var categorySearchText: String = ""
    @State private var amountText: String = ""
    @State private var selectedAccount: Account?
    
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    
    private var originalSignedAmount: Decimal = 0
    
    private var filteredCategories: [CategoryInfo] {
        let categories = CategoryList.categories(for: transactionType)
        if categorySearchText.isEmpty {
            return categories
        }
        return categories.filter { $0.name.localizedCaseInsensitiveContains(categorySearchText) }
    }
    
    init(transaction: Transaction) {
        self.transaction = transaction
        self._transactionType = State(initialValue: transaction.transactionType)
        self._date = State(initialValue: transaction.date)
        self._descriptionText = State(initialValue: transaction.descriptionText)
        self._selectedCategory = State(initialValue: transaction.category)
        self._categorySearchText = State(initialValue: transaction.category)
        self._amountText = State(initialValue: "\(transaction.amount)")
        self._selectedAccount = State(initialValue: transaction.account)
        self.originalSignedAmount = transaction.signedAmount
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
                    Picker(String(localized: "Account"), selection: $selectedAccount) {
                        Text(String(localized: "Select Account")).tag(nil as Account?)
                        ForEach(accounts) { account in
                            Label(account.name, systemImage: account.accountType.iconName)
                                .tag(account as Account?)
                        }
                    }
                }
                
                Section(String(localized: "Details")) {
                    DatePicker(String(localized: "Date"), selection: $date, displayedComponents: .date)
                    
                    TextField(String(localized: "Description"), text: $descriptionText)
                    
                    TextField(String(localized: "Amount"), text: $amountText)
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
            }
            .formStyle(.grouped)
            .navigationTitle(String(localized: "Edit Transaction"))
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
        }
        .frame(minWidth: 450, minHeight: 600)
    }
    
    private func saveTransaction() {
        guard let newAccount = selectedAccount else {
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
        
        // Revert old balance from old account
        if let oldAccount = transaction.account {
            oldAccount.balance -= originalSignedAmount
        }
        
        // Update transaction
        transaction.date = date
        transaction.descriptionText = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        transaction.category = category
        transaction.amount = amount
        transaction.transactionType = transactionType
        transaction.account = newAccount
        
        // Apply new balance to new account
        newAccount.balance += transaction.signedAmount
        
        dismiss()
    }
}

#Preview {
    @Previewable @State var transaction = Transaction(
        date: Date(),
        descriptionText: "Grocery shopping",
        category: "Groceries",
        amount: 50.00,
        transactionType: .expense
    )
    
    EditTransactionView(transaction: transaction)
        .modelContainer(for: Account.self, inMemory: true)
}
