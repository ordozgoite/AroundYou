//
//  AddBusinessView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 02/03/25.
//

import SwiftUI

struct PublishBusinessView: View {
    
    private let maxNameLenght = 30
    private let maxDescriptionLenght = 200
    
    @Binding var isViewDisplayed: Bool
    
    @State private var nameInput: String = "" {
        didSet {
            if nameInput.count > maxNameLenght {
                nameInput = String(nameInput.prefix(20))
            }
        }
    }
    @State private var descriptionInput: String = "" {
        didSet {
            if descriptionInput.count > maxDescriptionLenght {
                descriptionInput = String(descriptionInput.prefix(100))
            }
        }
    }
    @State private var selectedCategory: BusinessCategory? = nil
    
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                ImageView()
                
                Name()
                
                Description()
                
                Category()
            }
            .navigationTitle("Add Business")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Cancel()
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Publish()
                }
            }
        }
    }
    
    // MARK: - Image
    
    @ViewBuilder
    private func ImageView() -> some View {
        Section {
            VStack {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                
                Text("Add Photo")
                    .bold()
            }
            .foregroundStyle(.blue)
            .frame(height: 200)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    // MARK: - Name
    
    @ViewBuilder
    private func Name() -> some View {
        Section("Name") {
            TextField("Type your business' name", text: $nameInput)
        }
    }
    
    // MARK: - Description
    
    @ViewBuilder
    private func Description() -> some View {
        Section {
            TextField("Describe your business", text: $descriptionInput, axis: .vertical)
                .lineLimit(5...5)
        } header: {
            Text("Description")
        } footer: {
            Text("\(descriptionInput.count)/250")
                .frame(maxWidth: .infinity, alignment: .trailing)
        }

    }
    
    // MARK: - Category
    
    @ViewBuilder
    private func Category() -> some View {
        Section("Category") {
            Menu {
                ForEach(BusinessCategory.allCases, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(category.title)
                        if selectedCategory == category {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                HStack {
                    Text("Choose a Category")
                    Spacer()
                    Text(selectedCategory?.title ?? "")
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    // MARK: - Cancel
    
    @ViewBuilder
    private func Cancel() -> some View {
        Button("Cancel") {
            self.isViewDisplayed = false
        }
    }
    
    // MARK: - Publish
    
    @ViewBuilder
    private func Publish() -> some View {
        if isLoading {
            ProgressView()
        } else {
            Button("Publish") {
                // Post Business
            }
            .disabled(!areInputsValid())
        }
    }
}

// MARK: - Private Methods

extension PublishBusinessView {
    private func areInputsValid() -> Bool {
        return !(nameInput.isEmpty || descriptionInput.isEmpty || selectedCategory == nil)
    }
}

#Preview {
    PublishBusinessView(isViewDisplayed: .constant(true))
}
