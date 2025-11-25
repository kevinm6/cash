//
//  CategoryModel.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var name: String
    var icon: String
    var isExpense: Bool
    var isDefault: Bool
    var createdAt: Date
    
    init(
        name: String,
        icon: String,
        isExpense: Bool,
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.isExpense = isExpense
        self.isDefault = isDefault
        self.createdAt = Date()
    }
    
    static func createDefaultCategories() -> [Category] {
        var categories: [Category] = []
        
        // Expense categories
        let expenseData: [(String, String)] = [
            ("Food & Dining", "fork.knife"),
            ("Groceries", "cart.fill"),
            ("Transportation", "car.fill"),
            ("Utilities", "bolt.fill"),
            ("Housing", "house.fill"),
            ("Healthcare", "cross.case.fill"),
            ("Entertainment", "tv.fill"),
            ("Shopping", "bag.fill"),
            ("Education", "book.fill"),
            ("Travel", "airplane"),
            ("Insurance", "shield.fill"),
            ("Personal Care", "person.fill"),
            ("Gifts", "gift.fill"),
            ("Subscriptions", "repeat"),
            ("Other Expense", "ellipsis.circle.fill"),
        ]
        
        for (name, icon) in expenseData {
            categories.append(Category(name: name, icon: icon, isExpense: true, isDefault: true))
        }
        
        // Income categories
        let incomeData: [(String, String)] = [
            ("Salary", "briefcase.fill"),
            ("Freelance", "laptopcomputer"),
            ("Investments", "chart.line.uptrend.xyaxis"),
            ("Rental Income", "building.2.fill"),
            ("Dividends", "percent"),
            ("Interest", "banknote.fill"),
            ("Refund", "arrow.uturn.backward.circle.fill"),
            ("Gift Received", "gift.fill"),
            ("Other Income", "ellipsis.circle.fill"),
        ]
        
        for (name, icon) in incomeData {
            categories.append(Category(name: name, icon: icon, isExpense: false, isDefault: true))
        }
        
        return categories
    }
}
