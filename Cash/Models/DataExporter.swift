//
//  DataExporter.swift
//  Cash
//
//  Created by Michele Broggi on 26/11/25.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

// MARK: - Export Format

enum ExportFormat: String, CaseIterable, Identifiable {
    case json = "json"
    case csv = "csv"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .json:
            return "JSON"
        case .csv:
            return "CSV"
        }
    }
    
    var fileExtension: String {
        rawValue
    }
    
    var utType: UTType {
        switch self {
        case .json:
            return .json
        case .csv:
            return .commaSeparatedText
        }
    }
    
    var iconName: String {
        switch self {
        case .json:
            return "doc.badge.gearshape"
        case .csv:
            return "tablecells"
        }
    }
}

// MARK: - Exportable Data Structures

struct ExportableAccount: Codable {
    let id: UUID
    let name: String
    let accountNumber: String
    let currency: String
    let accountClass: String
    let accountType: String
    let isActive: Bool
    let isSystem: Bool
    let createdAt: Date
    
    init(from account: Account) {
        self.id = account.id
        self.name = account.name
        self.accountNumber = account.accountNumber
        self.currency = account.currency
        self.accountClass = account.accountClassRawValue
        self.accountType = account.accountTypeRawValue
        self.isActive = account.isActive
        self.isSystem = account.isSystem
        self.createdAt = account.createdAt
    }
}

struct ExportableEntry: Codable {
    let id: UUID
    let entryType: String
    let amount: String // Decimal as string for precision
    let accountId: UUID
    
    init(from entry: Entry) {
        self.id = entry.id
        self.entryType = entry.entryTypeRawValue
        self.amount = "\(entry.amount)"
        self.accountId = entry.account?.id ?? UUID()
    }
}

struct ExportableAttachment: Codable {
    let id: UUID
    let filename: String
    let mimeType: String
    let data: String // Base64 encoded
    let createdAt: Date
    
    init(from attachment: Attachment) {
        self.id = attachment.id
        self.filename = attachment.filename
        self.mimeType = attachment.mimeType
        self.data = attachment.data.base64EncodedString()
        self.createdAt = attachment.createdAt
    }
}

struct ExportableRecurrenceRule: Codable {
    let id: UUID
    let frequency: String
    let interval: Int
    let dayOfMonth: Int?
    let dayOfWeek: Int?
    let monthOfYear: Int?
    let weekendAdjustment: String
    let startDate: Date
    let endDate: Date?
    let nextOccurrence: Date?
    let isActive: Bool
    
    init(from rule: RecurrenceRule) {
        self.id = rule.id
        self.frequency = rule.frequencyRawValue
        self.interval = rule.interval
        self.dayOfMonth = rule.dayOfMonth
        self.dayOfWeek = rule.dayOfWeek
        self.monthOfYear = rule.monthOfYear
        self.weekendAdjustment = rule.weekendAdjustmentRawValue
        self.startDate = rule.startDate
        self.endDate = rule.endDate
        self.nextOccurrence = rule.nextOccurrence
        self.isActive = rule.isActive
    }
}

struct ExportableTransaction: Codable {
    let id: UUID
    let date: Date
    let descriptionText: String
    let reference: String
    let createdAt: Date
    let isRecurring: Bool
    let entries: [ExportableEntry]
    let attachments: [ExportableAttachment]
    let recurrenceRule: ExportableRecurrenceRule?
    
    init(from transaction: Transaction) {
        self.id = transaction.id
        self.date = transaction.date
        self.descriptionText = transaction.descriptionText
        self.reference = transaction.reference
        self.createdAt = transaction.createdAt
        self.isRecurring = transaction.isRecurring
        self.entries = (transaction.entries ?? []).map { ExportableEntry(from: $0) }
        self.attachments = (transaction.attachments ?? []).map { ExportableAttachment(from: $0) }
        self.recurrenceRule = transaction.recurrenceRule.map { ExportableRecurrenceRule(from: $0) }
    }
}

struct ExportableData: Codable {
    let version: String
    let exportDate: Date
    let accounts: [ExportableAccount]
    let transactions: [ExportableTransaction]
    
    init(accounts: [Account], transactions: [Transaction]) {
        self.version = "1.0"
        self.exportDate = Date()
        self.accounts = accounts.map { ExportableAccount(from: $0) }
        self.transactions = transactions.map { ExportableTransaction(from: $0) }
    }
}

// MARK: - CSV Row for Transactions

struct CSVTransactionRow {
    let transactionId: UUID
    let date: Date
    let description: String
    let reference: String
    let entryType: String
    let amount: Decimal
    let accountName: String
    let accountClass: String
    let accountType: String
    let currency: String
    
    static var headers: [String] {
        [
            "Transaction ID",
            "Date",
            "Description",
            "Reference",
            "Entry Type",
            "Amount",
            "Account Name",
            "Account Class",
            "Account Type",
            "Currency"
        ]
    }
    
    var values: [String] {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        
        return [
            transactionId.uuidString,
            dateFormatter.string(from: date),
            description.escapedForCSV,
            reference.escapedForCSV,
            entryType,
            "\(amount)",
            accountName.escapedForCSV,
            accountClass,
            accountType,
            currency
        ]
    }
}

private extension String {
    var escapedForCSV: String {
        if contains(",") || contains("\"") || contains("\n") {
            return "\"\(replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return self
    }
}

// MARK: - Data Exporter

enum DataExporterError: LocalizedError {
    case noData
    case encodingFailed
    case decodingFailed
    case invalidFormat
    case importFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noData:
            return String(localized: "No data to export")
        case .encodingFailed:
            return String(localized: "Failed to encode data")
        case .decodingFailed:
            return String(localized: "Failed to decode data")
        case .invalidFormat:
            return String(localized: "Invalid file format")
        case .importFailed(let reason):
            return String(localized: "Import failed: \(reason)")
        }
    }
}

struct DataExporter {
    
    // MARK: - Export JSON
    
    static func exportJSON(accounts: [Account], transactions: [Transaction]) throws -> Data {
        let exportData = ExportableData(accounts: accounts, transactions: transactions)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        guard let data = try? encoder.encode(exportData) else {
            throw DataExporterError.encodingFailed
        }
        
        return data
    }
    
    // MARK: - Export CSV
    
    static func exportCSV(transactions: [Transaction]) throws -> Data {
        var rows: [CSVTransactionRow] = []
        
        for transaction in transactions {
            for entry in transaction.entries ?? [] {
                guard let account = entry.account else { continue }
                
                let row = CSVTransactionRow(
                    transactionId: transaction.id,
                    date: transaction.date,
                    description: transaction.descriptionText,
                    reference: transaction.reference,
                    entryType: entry.entryTypeRawValue,
                    amount: entry.amount,
                    accountName: account.name,
                    accountClass: account.accountClassRawValue,
                    accountType: account.accountTypeRawValue,
                    currency: account.currency
                )
                rows.append(row)
            }
        }
        
        var csvString = CSVTransactionRow.headers.joined(separator: ",") + "\n"
        
        for row in rows {
            csvString += row.values.joined(separator: ",") + "\n"
        }
        
        guard let data = csvString.data(using: .utf8) else {
            throw DataExporterError.encodingFailed
        }
        
        return data
    }
    
    // MARK: - Import JSON
    
    static func importJSON(from data: Data, into context: ModelContext) throws -> (accountsCount: Int, transactionsCount: Int) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let exportData = try? decoder.decode(ExportableData.self, from: data) else {
            throw DataExporterError.decodingFailed
        }
        
        // Create a mapping from old UUIDs to new accounts
        var accountMapping: [UUID: Account] = [:]
        
        // Import accounts
        for exportedAccount in exportData.accounts {
            let account = Account(
                name: exportedAccount.name,
                accountNumber: exportedAccount.accountNumber,
                currency: exportedAccount.currency,
                accountClass: AccountClass(rawValue: exportedAccount.accountClass) ?? .asset,
                accountType: AccountType(rawValue: exportedAccount.accountType) ?? .bank,
                isActive: exportedAccount.isActive,
                isSystem: exportedAccount.isSystem
            )
            // Preserve original ID and dates
            account.id = exportedAccount.id
            account.createdAt = exportedAccount.createdAt
            
            context.insert(account)
            accountMapping[exportedAccount.id] = account
        }
        
        // Import transactions
        for exportedTransaction in exportData.transactions {
            let transaction = Transaction(
                date: exportedTransaction.date,
                descriptionText: exportedTransaction.descriptionText,
                reference: exportedTransaction.reference,
                isRecurring: exportedTransaction.isRecurring
            )
            transaction.id = exportedTransaction.id
            transaction.createdAt = exportedTransaction.createdAt
            
            context.insert(transaction)
            
            // Import entries
            for exportedEntry in exportedTransaction.entries {
                guard let account = accountMapping[exportedEntry.accountId] else {
                    throw DataExporterError.importFailed("Account not found for entry")
                }
                
                let entry = Entry(
                    entryType: EntryType(rawValue: exportedEntry.entryType) ?? .debit,
                    amount: Decimal(string: exportedEntry.amount) ?? 0,
                    account: account
                )
                entry.id = exportedEntry.id
                entry.transaction = transaction
                
                context.insert(entry)
            }
            
            // Import attachments
            for exportedAttachment in exportedTransaction.attachments {
                guard let attachmentData = Data(base64Encoded: exportedAttachment.data) else {
                    continue
                }
                
                let attachment = Attachment(
                    filename: exportedAttachment.filename,
                    mimeType: exportedAttachment.mimeType,
                    data: attachmentData
                )
                attachment.id = exportedAttachment.id
                attachment.createdAt = exportedAttachment.createdAt
                attachment.transaction = transaction
                
                context.insert(attachment)
            }
            
            // Import recurrence rule
            if let exportedRule = exportedTransaction.recurrenceRule {
                let rule = RecurrenceRule(
                    frequency: RecurrenceFrequency(rawValue: exportedRule.frequency) ?? .monthly,
                    interval: exportedRule.interval,
                    dayOfMonth: exportedRule.dayOfMonth,
                    dayOfWeek: exportedRule.dayOfWeek,
                    monthOfYear: exportedRule.monthOfYear,
                    weekendAdjustment: WeekendAdjustment(rawValue: exportedRule.weekendAdjustment) ?? .none,
                    startDate: exportedRule.startDate,
                    endDate: exportedRule.endDate
                )
                rule.id = exportedRule.id
                rule.nextOccurrence = exportedRule.nextOccurrence
                rule.isActive = exportedRule.isActive
                rule.transaction = transaction
                
                context.insert(rule)
            }
        }
        
        try context.save()
        
        return (exportData.accounts.count, exportData.transactions.count)
    }
    
    // MARK: - Generate Filename
    
    static func generateFilename(for format: ExportFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        return "Cash_Export_\(dateString).\(format.fileExtension)"
    }
}
