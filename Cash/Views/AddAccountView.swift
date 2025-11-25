//
//  AddAccountView.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import SwiftUI
import SwiftData

struct AddAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var accountNumber: String = ""
    @State private var selectedCurrency: String = "EUR"
    @State private var selectedType: AccountType = .bank
    @State private var initialBalance: String = ""
    
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Account Information")) {
                    TextField(String(localized: "Account Name"), text: $name)
                    TextField(String(localized: "Account Number"), text: $accountNumber)
                }
                
                Section(String(localized: "Account Type")) {
                    Picker(String(localized: "Type"), selection: $selectedType) {
                        ForEach(AccountType.allCases) { type in
                            Label(type.localizedName, systemImage: type.iconName)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                
                Section(String(localized: "Currency")) {
                    Picker(String(localized: "Currency"), selection: $selectedCurrency) {
                        ForEach(CurrencyList.currencies) { currency in
                            Text(currency.displayName)
                                .tag(currency.code)
                        }
                    }
                }
                
                Section(String(localized: "Initial Balance")) {
                    TextField(String(localized: "Balance"), text: $initialBalance)
                        .help(String(localized: "Enter the starting balance for this account"))
                }
            }
            .formStyle(.grouped)
            .navigationTitle(String(localized: "New Account"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        saveAccount()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .alert(String(localized: "Validation Error"), isPresented: $showingValidationError) {
                Button(String(localized: "OK"), role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
    
    private func saveAccount() {
        // Validate input
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            validationMessage = String(localized: "Please enter an account name.")
            showingValidationError = true
            return
        }
        
        // Parse initial balance
        var balance: Decimal = 0
        if !initialBalance.isEmpty {
            let cleanedBalance = initialBalance.replacingOccurrences(of: ",", with: ".")
            if let parsedBalance = Decimal(string: cleanedBalance) {
                balance = parsedBalance
            } else {
                validationMessage = String(localized: "Please enter a valid number for the balance.")
                showingValidationError = true
                return
            }
        }
        
        let account = Account(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            accountNumber: accountNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            currency: selectedCurrency,
            accountType: selectedType,
            balance: balance
        )
        
        modelContext.insert(account)
        dismiss()
    }
}

#Preview {
    AddAccountView()
        .modelContainer(for: Account.self, inMemory: true)
}
