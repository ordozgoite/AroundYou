//
//  UrgentScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 21/03/25.
//

import SwiftUI

enum UrgentFilterOption: CaseIterable {
    case all
    case lost
    case domesticViolence
    case animalViolence
    case sos
    
    var title: LocalizedStringKey {
        return switch self {
        case .all:
            "All"
        case .lost:
            "Lost items"
        case .domesticViolence:
            "Domestic Violence"
        case .animalViolence:
            "Animal Violence"
        case .sos:
            "Help"
        }
    }
    
    var iconName: String {
        return switch self {
        case .all:
            ""
        case .lost:
            "magnifyingglass"
        case .domesticViolence:
            "house"
        case .animalViolence:
            "dog"
        case .sos:
            "sos"
        }
    }
}

struct UrgentScreen: View {
    
    @State private var selectedFilterOption: UrgentFilterOption = .all
    
    var body: some View {
        NavigationStack {
            VStack {
                Filter()
                
                Spacer()
            }
            .toolbar {
                Plus()
            }
        }
    }
    
    // MARK: - Filter
    
    @ViewBuilder
    private func Filter() -> some View {
        Picker("Filter", selection: $selectedFilterOption) {
            ForEach(UrgentFilterOption.allCases, id: \.self) { option in
                Label(option.title, systemImage: option.iconName)
                    .tag(option)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .padding()
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    // MARK: - Plus
    
    @ViewBuilder
    private func Plus() -> some View {
        Menu {
            Button {
                // TODO: Go to Form
            } label: {
                Label("I lost something", systemImage: "magnifyingglass")
            }
            
            Button {
                // TODO: Go to Form
            } label: {
                Label("Report domestic violence", systemImage: "house")
            }
            
            Button {
                // TODO: Go to Form
            } label: {
                Label("Report animal abuse", systemImage: "dog")
            }
            
            Button {
                // TODO: Go to Form
            } label: {
                Label("Help me!", systemImage: "sos")
            }
        } label: {
            Image(systemName: "plus")
        }
        
    }
}

#Preview {
    UrgentScreen()
}
