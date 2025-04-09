//
//  ReportView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 25/03/25.
//

import SwiftUI
import PhotosUI

enum ReportType: String, Codable, CaseIterable {
    case human
    case animal
    case property
    
    var title: LocalizedStringKey {
        return switch self {
        case .human:
            "Harm to a Person"
        case .animal:
            "Animal Abuse"
        case .property:
            "Property Damage"
        }
    }
    
    var iconName: String {
        return switch self {
        case .human:
            "figure.stand"
        case .animal:
            "dog"
        case .property:
            "house.fill"
        }
    }
}

struct ReportView: View {
    
    @Binding var isViewDisplayed: Bool
    @State private var selectedReportType: ReportType?
    @State private var isUserTheVictim: Bool = true
    @State private var humanVictimDetails: String = ""
    @State private var reportDescription: String = ""
    @State private var imageSelection: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Type()
                
                if selectedReportType != nil {
                    Description()
                    
                    Picture()
                }
            }
            .navigationTitle("Report an Incident")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Cancel()
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Post()
                }
            }
        }
    }
    
    // MARK: - Type
    
    @ViewBuilder
    private func Type() -> some View {
        Section("Report Type") {
            Menu {
                ForEach(ReportType.allCases, id: \.self) { type in
                    Button {
                        selectedReportType = type
                    } label: {
                        Label(type.title, systemImage: type.iconName)
                        
                        if selectedReportType == type {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                HStack {
                    Text("What are you reporting?")
                    Spacer()
                    Label(selectedReportType?.title ?? "", systemImage: selectedReportType?.iconName ?? "")
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    // MARK: - Description
    
    @ViewBuilder
    private func Description() -> some View {
        Section("Description") {
            if selectedReportType == .human {
                Toggle("Are you the victim?", isOn: $isUserTheVictim)
                
                if !isUserTheVictim {
                    TextField("Describe the victim (optional)", text: $humanVictimDetails)
                }
            }
            
            TextField("Describe the incident", text: $reportDescription)
        }
    }
    
    // MARK: - Picture
    
    @ViewBuilder
    private func Picture() -> some View {
        Section(header: Text("Add a Picture (Optional)")) {
            ZStack(alignment: .topTrailing) {
                PhotosPicker(selection: $imageSelection, matching: .images) {
                    ReportImage()
                }
                
                if selectedImage != nil {
                    Button {
                        removePhoto()
                    } label: {
                        RemoveMediaButton(size: .medium)
                    }
                }
            }
        }
    }
    
    // MARK: - Report Image
    
    @ViewBuilder
    private func ReportImage() -> some View {
        if let image = selectedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .listRowBackground(Color(.systemGroupedBackground))
        } else {
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
    
    // MARK: - Cancel
    
    @ViewBuilder
    private func Cancel() -> some View {
        Button("Cancel") {
            self.isViewDisplayed = false
        }
    }
    
    // MARK: - Post
    
    @ViewBuilder
    private func Post() -> some View {
        Button("Post") {
            // TODO: Post Report
        }
    }
}

extension ReportView {
    private func removePhoto() {
        self.imageSelection = nil
        self.selectedImage = nil
    }
}

#Preview {
    ReportView(isViewDisplayed: .constant(true))
}
