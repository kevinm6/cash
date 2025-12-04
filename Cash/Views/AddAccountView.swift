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
    @Environment(AppSettings.self) private var settings
    @Query(sort: \Account.accountNumber) private var accounts: [Account]
    
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var name: String = ""
    @State private var accountNumber: String = ""
    @State private var selectedCurrency: String = "EUR"
    @State private var selectedClass: AccountClass = .asset
    @State private var selectedType: AccountType = .bank
    @State private var initialBalance: String = ""
    @State private var createOpeningBalance: Bool = false
    @State private var includedInBudget: Bool = false
    
    @State private var showingValidationError = false
    @State private var validationMessage: LocalizedStringKey = ""
    @State private var showingPaywall = false
    @State private var paywallFeature: PremiumFeature = .unlimitedAccounts
    
    private var availableTypes: [AccountType] {
        AccountType.types(for: selectedClass)
    }
    
    private var openingBalanceEquityAccount: Account? {
        accounts.first { $0.accountType == .openingBalance && $0.isSystem }
    }
    
    /// Count of real accounts (asset/liability, excluding system accounts)
    private var realAccountsCount: Int {
        accounts.filter { ($0.accountClass == .asset || $0.accountClass == .liability) && !$0.isSystem }.count
    }
    
    /// Count of category accounts (income/expense)
    private var categoriesCount: Int {
        accounts.filter { $0.accountClass == .income || $0.accountClass == .expense }.count
    }
    
    /// Whether user can create the selected account type
    private var canCreateSelectedType: Bool {
        if selectedClass == .asset || selectedClass == .liability {
            return subscriptionManager.canCreateAccount(currentCount: realAccountsCount)
        } else if selectedClass == .income || selectedClass == .expense {
            return subscriptionManager.canCreateCategory(currentCount: categoriesCount)
        }
        return true // equity accounts are always allowed
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Premium limit warning
                if !canCreateSelectedType {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .font(.title2)
                                .foregroundStyle(.yellow)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                if selectedClass == .asset || selectedClass == .liability {
                                    Text("Account limit reached")
                                        .font(.headline)
                                    Text("Free users can create up to \(FreeTierLimits.maxAccounts) accounts.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Category limit reached")
                                        .font(.headline)
                                    Text("Free users can create up to \(FreeTierLimits.maxCategories) categories.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button("Upgrade") {
                                paywallFeature = (selectedClass == .asset || selectedClass == .liability) ? .unlimitedAccounts : .unlimitedCategories
                                showingPaywall = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Account information") {
                    TextField("Account name", text: $name)
                    TextField("Account number", text: $accountNumber)
                        .help("Optional number for organizing accounts (e.g., 1000, 2000)")
                }
                
                Section("Account class") {
                    Picker("Class", selection: $selectedClass) {
                        ForEach(AccountClass.allCases) { accountClass in
                            Label(accountClass.localizedName, systemImage: accountClass.iconName)
                                .tag(accountClass)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .onChange(of: selectedClass) {
                        if let firstType = availableTypes.first {
                            selectedType = firstType
                        }
                    }
                }
                
                Section("Account type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(availableTypes) { type in
                            Label(type.localizedName, systemImage: type.iconName)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                
                Section("Currency") {
                    Picker("Currency", selection: $selectedCurrency) {
                        ForEach(CurrencyList.currencies) { currency in
                            Text(currency.displayName)
                                .tag(currency.code)
                        }
                    }
                }
                
                if selectedClass == .asset || selectedClass == .liability {
                    Section("Opening balance") {
                        Toggle("Set opening balance", isOn: $createOpeningBalance)
                        
                        if createOpeningBalance {
                            TextField("Amount", text: $initialBalance)
                                .help("Enter the starting balance for this account")
                        }
                    }
                }
                
                if selectedClass == .expense {
                    Section {
                        Toggle("Include in Budget", isOn: $includedInBudget)
                    } header: {
                        Text("Budget")
                    } footer: {
                        Text("Enable this to use this category as an envelope in your budget.")
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAccount()
                    }
                    .disabled(name.isEmpty || !canCreateSelectedType)
                }
            }
            .alert("Validation error", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .sheet(isPresented: $showingPaywall) {
                SubscriptionPaywallView(feature: paywallFeature)
            }
            .onAppear {
                if let firstType = availableTypes.first {
                    selectedType = firstType
                }
            }
            .id(settings.refreshID)
        }
        .frame(minWidth: 400, minHeight: 550)
    }
    
    private func saveAccount() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            validationMessage = "Please enter an account name."
            showingValidationError = true
            return
        }
        
        var balance: Decimal = 0
        if createOpeningBalance && !initialBalance.isEmpty {
            let parsed = CurrencyFormatter.parse(initialBalance)
            if parsed > 0 {
                balance = parsed
            } else if !initialBalance.isEmpty {
                validationMessage = "Please enter a valid number for the balance."
                showingValidationError = true
                return
            }
        }
        
        let account = Account(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            accountNumber: accountNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            currency: selectedCurrency,
            accountClass: selectedClass,
            accountType: selectedType,
            includedInBudget: selectedClass == .expense ? includedInBudget : false
        )
        
        modelContext.insert(account)
        
        if createOpeningBalance && balance > 0 {
            // Find or create the Opening Balance Equity account
            let equityAccount: Account
            if let existingEquity = openingBalanceEquityAccount {
                equityAccount = existingEquity
            } else {
                // Create the Opening Balance Equity account if it doesn't exist
                equityAccount = Account(
                    name: AccountType.openingBalance.localizedName,
                    accountNumber: "",
                    currency: selectedCurrency,
                    accountClass: .equity,
                    accountType: .openingBalance,
                    isSystem: true
                )
                modelContext.insert(equityAccount)
            }
            
            _ = TransactionBuilder.createOpeningBalance(
                account: account,
                amount: balance,
                openingBalanceEquityAccount: equityAccount,
                context: modelContext
            )
        }
        
        dismiss()
    }
}

#Preview {
    AddAccountView()
        .modelContainer(for: Account.self, inMemory: true)
        .environment(AppSettings.shared)
}
