//
//  AYFeatureSelector.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 20/03/25.
//

import SwiftUI

struct AYFeatureSelector: View {
    @Binding var selectedSection: HomeSection
    
    var body: some View {
        HStack {
            ForEach(HomeSection.allCases, id: \.self) { section in
                ItemView(forSection: section)
                    .animation(.spring(), value: selectedSection)
            }
        }
        .padding()
    }
    
    // MARK: - Item
    
    @ViewBuilder
    private func ItemView(forSection section: HomeSection) -> some View {
        HStack {
            Icon(forSection: section)
            
            Title(forSection: section)
        }
        .padding()
        .frame(maxWidth: selectedSection == section ? .infinity : nil)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(selectedSection == section ? section.color : .gray.opacity(0.2))
                .animation(.easeInOut, value: selectedSection)
        )
        .onTapGesture {
            if self.selectedSection != section {
                changeSelectedSection(section)
            }
        }
    }
    
    // MARK: - Icon
    
    @ViewBuilder
    private func Icon(forSection section: HomeSection) -> some View {
        Image(systemName: section.iconName)
            .resizable()
            .scaledToFit()
            .frame(height: 24)
            .foregroundColor(selectedSection == section ? .white : .gray)
            .transition(.opacity)
    }
    
    // MARK: - Title
    
    @ViewBuilder
    private func Title(forSection section: HomeSection) -> some View {
        if selectedSection == section {
            Text(section.title)
                .foregroundStyle(.white)
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }
}

// MARK: - Private Methods

extension AYFeatureSelector {
    private func changeSelectedSection(_ section: HomeSection) {
        withAnimation(.spring()) {
            hapticFeedback(style: .soft)
            self.selectedSection = section
        }
    }
}

#Preview {
    AYFeatureSelector(selectedSection: .constant(.places))
}
