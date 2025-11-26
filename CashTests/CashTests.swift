//
//  CashTests.swift
//  CashTests
//
//  Created by Michele Broggi on 25/11/25.
//

import Testing
import Foundation
@testable import Cash

struct AccountTests {
    
    @Test func accountCreation() async throws {
        let account = Account(
            name: "Test Bank",
            accountNumber: "1000",
            currency: "EUR",
            accountClass: .asset,
            accountType: .bank
        )
        
        #expect(account.name == "Test Bank")
        #expect(account.accountNumber == "1000")
        #expect(account.currency == "EUR")
        #expect(account.accountClass == .asset)
        #expect(account.accountType == .bank)
        #expect(account.isActive == true)
        #expect(account.isSystem == false)
    }
    
    @Test func accountDisplayName() async throws {
        let account = Account(
            name: "Checking",
            accountNumber: "1010",
            currency: "EUR",
            accountClass: .asset,
            accountType: .bank
        )
        
        // displayName returns just the name
        #expect(account.displayName == "Checking")
        #expect(account.accountNumber == "1010")
    }
    
    @Test func accountClassNormalBalance() async throws {
        #expect(AccountClass.asset.normalBalance == .debit)
        #expect(AccountClass.expense.normalBalance == .debit)
        #expect(AccountClass.liability.normalBalance == .credit)
        #expect(AccountClass.income.normalBalance == .credit)
        #expect(AccountClass.equity.normalBalance == .credit)
    }
}

struct TransactionTests {
    
    @Test func transactionCreation() async throws {
        let transaction = Transaction(
            date: Date(),
            descriptionText: "Test transaction"
        )
        
        #expect(transaction.descriptionText == "Test transaction")
        #expect(transaction.isRecurring == false)
    }
    
    @Test func transactionAmount() async throws {
        let transaction = Transaction(
            date: Date(),
            descriptionText: "Purchase"
        )
        
        let debitEntry = Entry(entryType: .debit, amount: 100)
        let creditEntry = Entry(entryType: .credit, amount: 100)
        
        transaction.entries = [debitEntry, creditEntry]
        
        #expect(transaction.amount == 100)
    }
    
    @Test func transactionIsBalanced() async throws {
        let transaction = Transaction(
            date: Date(),
            descriptionText: "Balanced"
        )
        
        let debitEntry = Entry(entryType: .debit, amount: 50)
        let creditEntry = Entry(entryType: .credit, amount: 50)
        
        transaction.entries = [debitEntry, creditEntry]
        
        #expect(transaction.isBalanced == true)
        #expect(transaction.totalDebits == transaction.totalCredits)
    }
}

struct EntryTests {
    
    @Test func entryTypeRawValues() async throws {
        #expect(EntryType.debit.rawValue == "debit")
        #expect(EntryType.credit.rawValue == "credit")
    }
    
    @Test func entryTypeOpposite() async throws {
        #expect(EntryType.debit.opposite == .credit)
        #expect(EntryType.credit.opposite == .debit)
    }
    
    @Test func entryCreation() async throws {
        let entry = Entry(entryType: .debit, amount: 50.25)
        
        #expect(entry.amount == 50.25)
        #expect(entry.entryType == .debit)
    }
}

struct CurrencyTests {
    
    @Test func currencySymbol() async throws {
        #expect(CurrencyList.symbol(forCode: "EUR") == "€")
        #expect(CurrencyList.symbol(forCode: "USD") == "$")
        #expect(CurrencyList.symbol(forCode: "GBP") == "£")
        #expect(CurrencyList.symbol(forCode: "INVALID") == "INVALID")
    }
    
    @Test func currencyListNotEmpty() async throws {
        #expect(CurrencyList.currencies.count > 0)
    }
    
    @Test func currencyLookup() async throws {
        let eur = CurrencyList.currency(forCode: "EUR")
        #expect(eur != nil)
        #expect(eur?.symbol == "€")
        #expect(eur?.name == "Euro")
    }
}

struct TransactionDateFilterTests {
    
    @Test func dateFilterRanges() async throws {
        let today = TransactionDateFilter.today
        let range = today.dateRange
        
        #expect(range.start <= range.end)
    }
    
    @Test func thisMonthFilter() async throws {
        let thisMonth = TransactionDateFilter.thisMonth
        let range = thisMonth.dateRange
        let calendar = Calendar.current
        
        let startComponents = calendar.dateComponents([.day], from: range.start)
        #expect(startComponents.day == 1)
    }
    
    @Test func allFiltersHaveValidRanges() async throws {
        for filter in TransactionDateFilter.allCases {
            let range = filter.dateRange
            #expect(range.start <= range.end)
        }
    }
}
