//
//  Account.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import Foundation
import SwiftData

enum AccountType: String, Codable, CaseIterable, Identifiable {
    case bank = "bank"
    case cash = "cash"
    case investment = "investment"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .bank:
            return String(localized: "Bank Account")
        case .cash:
            return String(localized: "Cash Account")
        case .investment:
            return String(localized: "Investment Account")
        }
    }
    
    var iconName: String {
        switch self {
        case .bank:
            return "building.columns"
        case .cash:
            return "banknote"
        case .investment:
            return "chart.line.uptrend.xyaxis"
        }
    }
}

@Model
final class Account {
    var id: UUID
    var name: String
    var accountNumber: String
    var currency: String
    var typeRawValue: String
    var createdAt: Date
    var balance: Decimal
    
    @Relationship(deleteRule: .cascade, inverse: \Transaction.account)
    var transactions: [Transaction]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \RecurringTransaction.account)
    var recurringTransactions: [RecurringTransaction]? = []
    
    var accountType: AccountType {
        get { AccountType(rawValue: typeRawValue) ?? .bank }
        set { typeRawValue = newValue.rawValue }
    }
    
    init(
        name: String,
        accountNumber: String,
        currency: String,
        accountType: AccountType,
        balance: Decimal = 0
    ) {
        self.id = UUID()
        self.name = name
        self.accountNumber = accountNumber
        self.currency = currency
        self.typeRawValue = accountType.rawValue
        self.createdAt = Date()
        self.balance = balance
    }
}
