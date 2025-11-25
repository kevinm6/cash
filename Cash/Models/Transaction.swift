//
//  Transaction.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import Foundation
import SwiftData

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case income = "income"
    case expense = "expense"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .income:
            return String(localized: "Income")
        case .expense:
            return String(localized: "Expense")
        }
    }
    
    var iconName: String {
        switch self {
        case .income:
            return "arrow.down.circle.fill"
        case .expense:
            return "arrow.up.circle.fill"
        }
    }
}

@Model
final class Transaction {
    var id: UUID
    var date: Date
    var descriptionText: String
    var category: String
    var amount: Decimal
    var typeRawValue: String
    var createdAt: Date
    
    var account: Account?
    
    var transactionType: TransactionType {
        get { TransactionType(rawValue: typeRawValue) ?? .expense }
        set { typeRawValue = newValue.rawValue }
    }
    
    var signedAmount: Decimal {
        transactionType == .income ? amount : -amount
    }
    
    init(
        date: Date = Date(),
        descriptionText: String,
        category: String,
        amount: Decimal,
        transactionType: TransactionType,
        account: Account? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.descriptionText = descriptionText
        self.category = category
        self.amount = amount
        self.typeRawValue = transactionType.rawValue
        self.createdAt = Date()
        self.account = account
    }
}
