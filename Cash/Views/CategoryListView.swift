//
//  CategoryListView.swift
//  Cash
//
//  Created by Michele Broggi on 25/11/25.
//

import SwiftUI
import SwiftData

struct CategoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]
    @State private var showingAddCategory = false
    @State private var categoryToEdit: Category?
    @State private var categoryToDelete: Category?
    @State private var selectedType: TransactionType = .expense
    
    private var filteredCategories: [Category] {
        categories.filter { $0.isExpense == (selectedType == .expense) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker(String(localized: "Type"), selection: $selectedType) {
                ForEach(TransactionType.allCases) { type in
                    Text(type.localizedName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            Divider()
            
            if filteredCategories.isEmpty {
                ContentUnavailableView {
                    Label(String(localized: "No Categories"), systemImage: "tag")
                } description: {
                    Text("Add your first category.")
                } actions: {
                    Button(String(localized: "Add Category")) {
                        showingAddCategory = true
                    }
                }
            } else {
                List {
                    ForEach(filteredCategories) { category in
                        CategoryRowView(category: category)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                categoryToEdit = category
                            }
                            .contextMenu {
                                Button {
                                    categoryToEdit = category
                                } label: {
                                    Label(String(localized: "Edit"), systemImage: "pencil")
                                }
                                
                                if !category.isDefault {
                                    Button(role: .destructive) {
                                        categoryToDelete = category
                                    } label: {
                                        Label(String(localized: "Delete"), systemImage: "trash")
                                    }
                                }
                            }
                    }
                    .onDelete { indexSet in
                        deleteCategories(at: indexSet)
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Categories"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddCategory = true }) {
                    Label(String(localized: "Add Category"), systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView(isExpense: selectedType == .expense)
        }
        .sheet(item: $categoryToEdit) { category in
            EditCategoryView(category: category)
        }
        .confirmationDialog(
            String(localized: "Delete Category"),
            isPresented: Binding(
                get: { categoryToDelete != nil },
                set: { if !$0 { categoryToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(String(localized: "Delete"), role: .destructive) {
                if let category = categoryToDelete {
                    modelContext.delete(category)
                }
            }
            Button(String(localized: "Cancel"), role: .cancel) {
                categoryToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this category?")
        }
        .onAppear {
            initializeDefaultCategoriesIfNeeded()
        }
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            let category = filteredCategories[index]
            if !category.isDefault {
                modelContext.delete(category)
            }
        }
    }
    
    private func initializeDefaultCategoriesIfNeeded() {
        if categories.isEmpty {
            let defaultCategories = Category.createDefaultCategories()
            for category in defaultCategories {
                modelContext.insert(category)
            }
        }
    }
}

struct CategoryRowView: View {
    let category: Category
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundColor(category.isExpense ? .red : .green)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(category.name)
                        .font(.headline)
                    
                    if category.isDefault {
                        Text(String(localized: "Default"))
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        CategoryListView()
    }
    .modelContainer(for: Category.self, inMemory: true)
}
