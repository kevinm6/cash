//
//  EditCategoryView.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import SwiftUI
import SwiftData

struct EditCategoryView: View {
    @Bindable var category: Category
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "tag.fill"
    @State private var categoryType: TransactionType = .expense
    
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    
    private let availableIcons = [
        "tag.fill", "cart.fill", "bag.fill", "creditcard.fill",
        "fork.knife", "cup.and.saucer.fill", "takeoutbag.and.cup.and.straw.fill",
        "car.fill", "bus.fill", "tram.fill", "airplane", "fuelpump.fill",
        "house.fill", "building.2.fill", "bolt.fill", "drop.fill",
        "cross.case.fill", "pills.fill", "heart.fill",
        "tv.fill", "gamecontroller.fill", "headphones", "music.note",
        "book.fill", "graduationcap.fill", "pencil",
        "gift.fill", "party.popper.fill",
        "briefcase.fill", "laptopcomputer", "desktopcomputer",
        "chart.line.uptrend.xyaxis", "percent", "banknote.fill",
        "shield.fill", "lock.fill",
        "person.fill", "figure.walk", "dumbbell.fill",
        "pawprint.fill", "leaf.fill", "tree.fill",
        "phone.fill", "wifi", "globe",
        "wrench.fill", "hammer.fill",
        "repeat", "arrow.triangle.2.circlepath",
        "star.fill", "heart.circle.fill",
        "ellipsis.circle.fill"
    ]
    
    init(category: Category) {
        self.category = category
        self._name = State(initialValue: category.name)
        self._selectedIcon = State(initialValue: category.icon)
        self._categoryType = State(initialValue: category.isExpense ? .expense : .income)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Category Information")) {
                    TextField(String(localized: "Category Name"), text: $name)
                    
                    if !category.isDefault {
                        Picker(String(localized: "Type"), selection: $categoryType) {
                            ForEach(TransactionType.allCases) { type in
                                Text(type.localizedName).tag(type)
                            }
                        }
                    } else {
                        HStack {
                            Text(String(localized: "Type"))
                            Spacer()
                            Text(categoryType.localizedName)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section(String(localized: "Icon")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedIcon == icon ? Color.accentColor : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(categoryType == .expense ? .red : .green)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                if category.isDefault {
                    Section {
                        Text("Default categories cannot be deleted or change type.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(String(localized: "Edit Category"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        saveCategory()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .alert(String(localized: "Validation Error"), isPresented: $showingValidationError) {
                Button(String(localized: "OK"), role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
    
    private func saveCategory() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            validationMessage = String(localized: "Please enter a category name.")
            showingValidationError = true
            return
        }
        
        category.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        category.icon = selectedIcon
        if !category.isDefault {
            category.isExpense = categoryType == .expense
        }
        
        dismiss()
    }
}

#Preview {
    @Previewable @State var category = Category(
        name: "Food",
        icon: "fork.knife",
        isExpense: true
    )
    
    EditCategoryView(category: category)
        .modelContainer(for: Category.self, inMemory: true)
}
