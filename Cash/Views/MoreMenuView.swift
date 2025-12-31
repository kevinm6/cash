//
//  MoreMenuView.swift
//  Cash
//
//  Menu view for additional features: Loans, Reports, Scheduled, Settings
//

import SwiftUI
import SwiftData

struct MoreMenuView: View {
    @Environment(AppSettings.self) private var settings
    @State private var showingSettings = false
    @State private var appState = AppState()

    var body: some View {
        NavigationStack {
            List {
                // Finance Tools Section
                Section {
                    NavigationLink {
                        LoansView()
                    } label: {
                        MoreMenuRow(
                            icon: "building.columns.fill",
                            title: "Loans & Mortgages",
                            subtitle: "Manage loans and view amortization",
                            color: CashColors.primary
                        )
                    }

                    NavigationLink {
                        ForecastView()
                    } label: {
                        MoreMenuRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Forecast",
                            subtitle: "Project future balances",
                            color: .blue
                        )
                    }

                    NavigationLink {
                        ScheduledTransactionsView()
                    } label: {
                        MoreMenuRow(
                            icon: "calendar.badge.clock",
                            title: "Scheduled Transactions",
                            subtitle: "Recurring and upcoming payments",
                            color: .orange
                        )
                    }

                    NavigationLink {
                        NetWorthView()
                    } label: {
                        MoreMenuRow(
                            icon: "chart.bar.fill",
                            title: "Net Worth",
                            subtitle: "Assets and liabilities overview",
                            color: CashColors.success
                        )
                    }
                } header: {
                    Text("Finance Tools")
                }

                // Analytics Section
                Section {
                    NavigationLink {
                        ReportsView()
                    } label: {
                        MoreMenuRow(
                            icon: "doc.text.fill",
                            title: "Reports",
                            subtitle: "Expense analysis and trends",
                            color: .purple
                        )
                    }

                    NavigationLink {
                        LoanCalculatorView()
                    } label: {
                        MoreMenuRow(
                            icon: "function",
                            title: "Loan Calculator",
                            subtitle: "Calculate payments and interest",
                            color: .indigo
                        )
                    }
                } header: {
                    Text("Analytics")
                }

                // Data Section
                Section {
                    Button {
                        NotificationCenter.default.post(name: .importOFX, object: nil)
                    } label: {
                        MoreMenuRow(
                            icon: "square.and.arrow.down.fill",
                            title: "Import Transactions",
                            subtitle: "Import from OFX/QFX files",
                            color: .cyan
                        )
                    }
                } header: {
                    Text("Data")
                }

                // Settings Section
                Section {
                    Button {
                        showingSettings = true
                    } label: {
                        MoreMenuRow(
                            icon: "gear",
                            title: "Settings",
                            subtitle: "Theme, language, and preferences",
                            color: .gray
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("More")
            .sheet(isPresented: $showingSettings) {
                SettingsView(appState: appState) {
                    showingSettings = false
                }
            }
        }
    }
}

// MARK: - More Menu Row

struct MoreMenuRow: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let color: Color

    var body: some View {
        HStack(spacing: CashSpacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: CashRadius.small))

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(CashTypography.body)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(CashTypography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, CashSpacing.xs)
    }
}

// MARK: - Preview

#Preview {
    MoreMenuView()
        .modelContainer(for: [Account.self, Transaction.self], inMemory: true)
        .environment(AppSettings.shared)
}
