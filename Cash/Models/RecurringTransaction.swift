//
//  RecurringTransaction.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import Foundation
import SwiftData

enum RecurrenceFrequency: String, Codable, CaseIterable, Identifiable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .daily:
            return String(localized: "Daily")
        case .weekly:
            return String(localized: "Weekly")
        case .monthly:
            return String(localized: "Monthly")
        }
    }
}

enum WeekDay: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var id: Int { rawValue }
    
    var localizedName: String {
        switch self {
        case .sunday:
            return String(localized: "Sunday")
        case .monday:
            return String(localized: "Monday")
        case .tuesday:
            return String(localized: "Tuesday")
        case .wednesday:
            return String(localized: "Wednesday")
        case .thursday:
            return String(localized: "Thursday")
        case .friday:
            return String(localized: "Friday")
        case .saturday:
            return String(localized: "Saturday")
        }
    }
    
    var shortName: String {
        switch self {
        case .sunday:
            return String(localized: "Sun")
        case .monday:
            return String(localized: "Mon")
        case .tuesday:
            return String(localized: "Tue")
        case .wednesday:
            return String(localized: "Wed")
        case .thursday:
            return String(localized: "Thu")
        case .friday:
            return String(localized: "Fri")
        case .saturday:
            return String(localized: "Sat")
        }
    }
    
    var isWeekend: Bool {
        self == .saturday || self == .sunday
    }
}

enum WeekendHandling: String, Codable, CaseIterable, Identifiable {
    case none = "none"
    case prepone = "prepone"
    case postpone = "postpone"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .none:
            return String(localized: "Execute on weekend")
        case .prepone:
            return String(localized: "Move to Friday")
        case .postpone:
            return String(localized: "Move to Monday")
        }
    }
}

@Model
final class RecurringTransaction {
    var id: UUID
    var descriptionText: String
    var category: String
    var amount: Decimal
    var typeRawValue: String
    var frequencyRawValue: String
    var dayOfMonth: Int?
    var weekDayRawValue: Int?
    var weekendHandlingRawValue: String
    var startDate: Date
    var endDate: Date?
    var lastExecutedDate: Date?
    var isActive: Bool
    var createdAt: Date
    
    var account: Account?
    
    var transactionType: TransactionType {
        get { TransactionType(rawValue: typeRawValue) ?? .expense }
        set { typeRawValue = newValue.rawValue }
    }
    
    var frequency: RecurrenceFrequency {
        get { RecurrenceFrequency(rawValue: frequencyRawValue) ?? .monthly }
        set { frequencyRawValue = newValue.rawValue }
    }
    
    var weekDay: WeekDay? {
        get {
            guard let raw = weekDayRawValue else { return nil }
            return WeekDay(rawValue: raw)
        }
        set { weekDayRawValue = newValue?.rawValue }
    }
    
    var weekendHandling: WeekendHandling {
        get { WeekendHandling(rawValue: weekendHandlingRawValue) ?? .none }
        set { weekendHandlingRawValue = newValue.rawValue }
    }
    
    init(
        descriptionText: String,
        category: String,
        amount: Decimal,
        transactionType: TransactionType,
        frequency: RecurrenceFrequency,
        dayOfMonth: Int? = nil,
        weekDay: WeekDay? = nil,
        weekendHandling: WeekendHandling = .none,
        startDate: Date = Date(),
        endDate: Date? = nil,
        account: Account? = nil
    ) {
        self.id = UUID()
        self.descriptionText = descriptionText
        self.category = category
        self.amount = amount
        self.typeRawValue = transactionType.rawValue
        self.frequencyRawValue = frequency.rawValue
        self.dayOfMonth = dayOfMonth
        self.weekDayRawValue = weekDay?.rawValue
        self.weekendHandlingRawValue = weekendHandling.rawValue
        self.startDate = startDate
        self.endDate = endDate
        self.lastExecutedDate = nil
        self.isActive = true
        self.createdAt = Date()
        self.account = account
    }
    
    func nextExecutionDate(from date: Date = Date()) -> Date? {
        let calendar = Calendar.current
        var nextDate: Date?
        
        switch frequency {
        case .daily:
            nextDate = calendar.date(byAdding: .day, value: 1, to: date)
            
        case .weekly:
            if let weekDay = weekDay {
                var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
                components.weekday = weekDay.rawValue
                if let candidateDate = calendar.date(from: components), candidateDate <= date {
                    nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: candidateDate)
                } else {
                    nextDate = calendar.date(from: components)
                }
            }
            
        case .monthly:
            if let day = dayOfMonth {
                var components = calendar.dateComponents([.year, .month], from: date)
                components.day = min(day, 28)
                if let candidateDate = calendar.date(from: components), candidateDate <= date {
                    nextDate = calendar.date(byAdding: .month, value: 1, to: candidateDate)
                } else {
                    nextDate = calendar.date(from: components)
                }
            }
        }
        
        guard var resultDate = nextDate else { return nil }
        
        if weekendHandling != .none {
            let weekday = calendar.component(.weekday, from: resultDate)
            if weekday == 1 {
                let offset = weekendHandling == .prepone ? -2 : 1
                resultDate = calendar.date(byAdding: .day, value: offset, to: resultDate) ?? resultDate
            } else if weekday == 7 {
                let offset = weekendHandling == .prepone ? -1 : 2
                resultDate = calendar.date(byAdding: .day, value: offset, to: resultDate) ?? resultDate
            }
        }
        
        if let endDate = endDate, resultDate > endDate {
            return nil
        }
        
        return resultDate
    }
    
    func shouldExecute(on date: Date = Date()) -> Bool {
        guard isActive else { return false }
        
        if date < startDate { return false }
        if let endDate = endDate, date > endDate { return false }
        
        let calendar = Calendar.current
        
        if let lastExecuted = lastExecutedDate {
            if calendar.isDate(lastExecuted, inSameDayAs: date) {
                return false
            }
        }
        
        var targetDate = date
        
        if weekendHandling != .none {
            let weekday = calendar.component(.weekday, from: date)
            if weekday == 1 || weekday == 7 {
                return false
            }
        }
        
        switch frequency {
        case .daily:
            return true
            
        case .weekly:
            if let weekDay = weekDay {
                let currentWeekday = calendar.component(.weekday, from: targetDate)
                return currentWeekday == weekDay.rawValue
            }
            return false
            
        case .monthly:
            if let day = dayOfMonth {
                let currentDay = calendar.component(.day, from: targetDate)
                let daysInMonth = calendar.range(of: .day, in: .month, for: targetDate)?.count ?? 31
                let targetDay = min(day, daysInMonth)
                return currentDay == targetDay
            }
            return false
        }
    }
    
    func createTransaction() -> Transaction {
        Transaction(
            date: Date(),
            descriptionText: descriptionText,
            category: category,
            amount: amount,
            transactionType: transactionType,
            account: account
        )
    }
}
