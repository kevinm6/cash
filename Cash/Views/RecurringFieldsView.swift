//
//  RecurringFieldsView.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import SwiftUI

struct RecurringFieldsView: View {
    @Binding var frequency: RecurrenceFrequency
    @Binding var dayOfMonth: Int
    @Binding var selectedWeekDay: WeekDay
    @Binding var weekendHandling: WeekendHandling
    @Binding var startDate: Date
    @Binding var hasEndDate: Bool
    @Binding var endDate: Date
    
    var body: some View {
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
}

#Preview {
    @Previewable @State var frequency: RecurrenceFrequency = .monthly
    @Previewable @State var dayOfMonth: Int = 1
    @Previewable @State var selectedWeekDay: WeekDay = .monday
    @Previewable @State var weekendHandling: WeekendHandling = .none
    @Previewable @State var startDate: Date = Date()
    @Previewable @State var hasEndDate: Bool = false
    @Previewable @State var endDate: Date = Date().addingTimeInterval(365 * 24 * 60 * 60)
    
    Form {
        RecurringFieldsView(
            frequency: $frequency,
            dayOfMonth: $dayOfMonth,
            selectedWeekDay: $selectedWeekDay,
            weekendHandling: $weekendHandling,
            startDate: $startDate,
            hasEndDate: $hasEndDate,
            endDate: $endDate
        )
    }
}
