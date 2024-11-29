//
//  GenderPickerView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/11/24.
//

import SwiftUI

struct GenderPickerView: View {
    
    @Binding var selectedGender: Gender

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Gender.allCases, id: \.self) { gender in
                HStack {
                    Circle()
                        .fill(selectedGender == gender ? Color.blue : Color.gray)
                        .frame(width: 20, height: 20)
                        .animation(.easeInOut, value: selectedGender)

                    Text(gender.title)
                        .font(.headline)

                    Spacer()
                }
                .padding(.vertical, 8)
                .onTapGesture {
                    self.selectedGender = gender
                }
            }
        }
    }
}

#Preview {
//    GenderPickerView()
}
