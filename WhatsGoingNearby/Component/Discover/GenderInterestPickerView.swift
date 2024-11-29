//
//  GenderInterestPickerView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 26/11/24.
//

import SwiftUI

struct GenderInterestPickerView: View {
    
    @Binding var selectedGenders: Set<Gender>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Gender.allCases, id: \.self) { gender in
                HStack {
                    Circle()
                        .fill(selectedGenders.contains(gender) ? Color.blue : Color.gray)
                        .frame(width: 20, height: 20)
                        .animation(.easeInOut, value: selectedGenders)

                    Text(gender.title)
                        .font(.headline)

                    Spacer()
                }
                .padding(.vertical, 8)
                .onTapGesture {
                    toggleSelection(for: gender)
                }
            }
        }
    }

    private func toggleSelection(for option: Gender) {
        if selectedGenders.contains(option) {
            selectedGenders.remove(option)
        } else {
            selectedGenders.insert(option)
        }
    }
}

#Preview {
//    GenderInterestPickerView(selectedOptions: <#Binding<Set<Gender>>#>)
}
