//
//  Category.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import Foundation
import SwiftData

struct CategoryInfo: Identifiable, Hashable {
    let name: String
    let icon: String
    let isExpense: Bool
    
    var id: String { name }
}

struct CategoryList {
    static let defaultExpenseCategories: [CategoryInfo] = [
        CategoryInfo(name: "Food & Dining", icon: "fork.knife", isExpense: true),
        CategoryInfo(name: "Groceries", icon: "cart.fill", isExpense: true),
        CategoryInfo(name: "Transportation", icon: "car.fill", isExpense: true),
        CategoryInfo(name: "Utilities", icon: "bolt.fill", isExpense: true),
        CategoryInfo(name: "Housing", icon: "house.fill", isExpense: true),
        CategoryInfo(name: "Healthcare", icon: "cross.case.fill", isExpense: true),
        CategoryInfo(name: "Entertainment", icon: "tv.fill", isExpense: true),
        CategoryInfo(name: "Shopping", icon: "bag.fill", isExpense: true),
        CategoryInfo(name: "Education", icon: "book.fill", isExpense: true),
        CategoryInfo(name: "Travel", icon: "airplane", isExpense: true),
        CategoryInfo(name: "Insurance", icon: "shield.fill", isExpense: true),
        CategoryInfo(name: "Personal Care", icon: "person.fill", isExpense: true),
        CategoryInfo(name: "Gifts", icon: "gift.fill", isExpense: true),
        CategoryInfo(name: "Subscriptions", icon: "repeat", isExpense: true),
        CategoryInfo(name: "Other Expense", icon: "ellipsis.circle.fill", isExpense: true),
    ]
    
    static let defaultIncomeCategories: [CategoryInfo] = [
        CategoryInfo(name: "Salary", icon: "briefcase.fill", isExpense: false),
        CategoryInfo(name: "Freelance", icon: "laptopcomputer", isExpense: false),
        CategoryInfo(name: "Investments", icon: "chart.line.uptrend.xyaxis", isExpense: false),
        CategoryInfo(name: "Rental Income", icon: "building.2.fill", isExpense: false),
        CategoryInfo(name: "Dividends", icon: "percent", isExpense: false),
        CategoryInfo(name: "Interest", icon: "banknote.fill", isExpense: false),
        CategoryInfo(name: "Refund", icon: "arrow.uturn.backward.circle.fill", isExpense: false),
        CategoryInfo(name: "Gift Received", icon: "gift.fill", isExpense: false),
        CategoryInfo(name: "Other Income", icon: "ellipsis.circle.fill", isExpense: false),
    ]
    
    static func categories(for type: TransactionType) -> [CategoryInfo] {
        type == .expense ? defaultExpenseCategories : defaultIncomeCategories
    }
    
    static func categories(for type: TransactionType, from dbCategories: [Category]) -> [CategoryInfo] {
        let filtered = dbCategories.filter { $0.isExpense == (type == .expense) }
        if filtered.isEmpty {
            return categories(for: type)
        }
        return filtered.map { CategoryInfo(name: $0.name, icon: $0.icon, isExpense: $0.isExpense) }
    }
    
    static func icon(for categoryName: String) -> String {
        let all = defaultExpenseCategories + defaultIncomeCategories
        return all.first { $0.name == categoryName }?.icon ?? "circle.fill"
    }
    
    static func icon(for categoryName: String, from dbCategories: [Category]) -> String {
        if let category = dbCategories.first(where: { $0.name == categoryName }) {
            return category.icon
        }
        return icon(for: categoryName)
    }
}
