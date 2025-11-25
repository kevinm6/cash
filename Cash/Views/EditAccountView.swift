//
//  EditAccountView.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import SwiftUI
import SwiftData

struct EditAccountView: View {
    @Bindable var account: Account
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var accountNumber: String = ""
    @State private var selectedCurrency: String = "EUR"
    @State private var selectedType: AccountType = .bank
    @State private var balanceText: String = ""
    
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
                
                Section(String(localized: "Balance")) {
                    TextField(String(localized: "Balance"), text: $balanceText)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(String(localized: "Edit Account"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        saveChanges()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .alert(String(localized: "Validation Error"), isPresented: $showingValidationError) {
                Button(String(localized: "OK"), role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .onAppear {
                loadAccountData()
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
    
    private func loadAccountData() {
        name = account.name
        accountNumber = account.accountNumber
        selectedCurrency = account.currency
        selectedType = account.accountType
        balanceText = "\(account.balance)"
    }
    
    private func saveChanges() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            validationMessage = String(localized: "Please enter an account name.")
            showingValidationError = true
            return
        }
        
        var balance: Decimal = account.balance
        if !balanceText.isEmpty {
            let cleanedBalance = balanceText.replacingOccurrences(of: ",", with: ".")
            if let parsedBalance = Decimal(string: cleanedBalance) {
                balance = parsedBalance
            } else {
                validationMessage = String(localized: "Please enter a valid number for the balance.")
                showingValidationError = true
                return
            }
        }
        
        account.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        account.accountNumber = accountNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        account.currency = selectedCurrency
        account.accountType = selectedType
        account.balance = balance
        
        dismiss()
    }
}

#Preview {
    @Previewable @State var account = Account(
        name: "Main Checking",
        accountNumber: "1234567890",
        currency: "EUR",
        accountType: .bank,
        balance: 1000
    )
    
    EditAccountView(account: account)
        .modelContainer(for: Account.self, inMemory: true)
}
