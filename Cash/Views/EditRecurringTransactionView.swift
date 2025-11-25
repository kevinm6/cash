//
//  EditRecurringTransactionView.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import SwiftUI
import SwiftData

struct EditRecurringTransactionView: View {
    @Bindable var recurring: RecurringTransaction
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Account.name) private var accounts: [Account]
    
    @State private var transactionType: TransactionType = .expense
    @State private var descriptionText: String = ""
    @State private var selectedCategory: String = ""
    @State private var categorySearchText: String = ""
    @State private var amountText: String = ""
    @State private var selectedAccount: Account?
    
    @State private var frequency: RecurrenceFrequency = .monthly
    @State private var dayOfMonth: Int = 1
    @State private var selectedWeekDay: WeekDay = .monday
    @State private var weekendHandling: WeekendHandling = .none
    @State private var startDate: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date()
    @State private var isActive: Bool = true
    
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    
    private var filteredCategories: [CategoryInfo] {
        let categories = CategoryList.categories(for: transactionType)
        if categorySearchText.isEmpty {
            return categories
        }
        return categories.filter { $0.name.localizedCaseInsensitiveContains(categorySearchText) }
    }
    
    init(recurring: RecurringTransaction) {
        self.recurring = recurring
        self._transactionType = State(initialValue: recurring.transactionType)
        self._descriptionText = State(initialValue: recurring.descriptionText)
        self._selectedCategory = State(initialValue: recurring.category)
        self._categorySearchText = State(initialValue: recurring.category)
        self._amountText = State(initialValue: "\(recurring.amount)")
        self._selectedAccount = State(initialValue: recurring.account)
        self._frequency = State(initialValue: recurring.frequency)
        self._dayOfMonth = State(initialValue: recurring.dayOfMonth ?? 1)
        self._selectedWeekDay = State(initialValue: recurring.weekDay ?? .monday)
        self._weekendHandling = State(initialValue: recurring.weekendHandling)
        self._startDate = State(initialValue: recurring.startDate)
        self._hasEndDate = State(initialValue: recurring.endDate != nil)
        self._endDate = State(initialValue: recurring.endDate ?? Date().addingTimeInterval(365 * 24 * 60 * 60))
        self._isActive = State(initialValue: recurring.isActive)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Status")) {
                    Toggle(String(localized: "Active"), isOn: $isActive)
                }
                
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
                    .frame(minHeight: 100)
                }
                
                Section(String(localized: "Schedule")) {
                    Picker(String(localized: "Frequency"), selection: $frequency) {
                        ForEach(RecurrenceFrequency.allCases) { freq in
                            Text(freq.localizedName).tag(freq)
                        }
                    }
                    
                    switch frequency {
                    case .daily:
                        EmptyView()
                        
                    case .weekly:
                        Picker(String(localized: "Day of Week"), selection: $selectedWeekDay) {
                            ForEach(WeekDay.allCases) { day in
                                Text(day.localizedName).tag(day)
                            }
                        }
                        
                    case .monthly:
                        Picker(String(localized: "Day of Month"), selection: $dayOfMonth) {
                            ForEach(1...31, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                    }
                    
                    Picker(String(localized: "Weekend Handling"), selection: $weekendHandling) {
                        ForEach(WeekendHandling.allCases) { handling in
                            Text(handling.localizedName).tag(handling)
                        }
                    }
                }
                
                Section(String(localized: "Duration")) {
                    DatePicker(String(localized: "Start Date"), selection: $startDate, displayedComponents: .date)
                    
                    Toggle(String(localized: "Has End Date"), isOn: $hasEndDate)
                    
                    if hasEndDate {
                        DatePicker(String(localized: "End Date"), selection: $endDate, displayedComponents: .date)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(String(localized: "Edit Recurring Transaction"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        saveRecurring()
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
        .frame(minWidth: 500, minHeight: 700)
    }
    
    private func saveRecurring() {
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
        
        recurring.descriptionText = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        recurring.category = category
        recurring.amount = amount
        recurring.transactionType = transactionType
        recurring.frequency = frequency
        recurring.dayOfMonth = frequency == .monthly ? dayOfMonth : nil
        recurring.weekDay = frequency == .weekly ? selectedWeekDay : nil
        recurring.weekendHandling = weekendHandling
        recurring.startDate = startDate
        recurring.endDate = hasEndDate ? endDate : nil
        recurring.isActive = isActive
        recurring.account = account
        
        dismiss()
    }
}

#Preview {
    @Previewable @State var recurring = RecurringTransaction(
        descriptionText: "Netflix",
        category: "Subscriptions",
        amount: 15.99,
        transactionType: .expense,
        frequency: .monthly,
        dayOfMonth: 15
    )
    
    EditRecurringTransactionView(recurring: recurring)
        .modelContainer(for: Account.self, inMemory: true)
}
