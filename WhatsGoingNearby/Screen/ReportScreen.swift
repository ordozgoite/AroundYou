//
//  ReportScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/02/24.
//

import SwiftUI

enum ReportTarget {
    case user
    case publication
    case comment
}

struct ReportScreen: View {
    
    private let maxDescriptionLenght = 500
    @State private var descriptionTextInput: String = ""
    
    var body: some View {
        VStack {
            HStack {
                Text("What type of issue are you reporting?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            
            Spacer()
            
            TextField("Describe what happened...", text: $descriptionTextInput, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(10...10)
            
            HStack {
                Spacer()
                Text("\(descriptionTextInput.count)/\(maxDescriptionLenght)")
                    .foregroundStyle(.gray)
                    .font(.subheadline)
            }
            
            Spacer()
            
            AYButton(title: "Report") {
                // report
            }
        }
        .padding()
    }
}

#Preview {
    ReportScreen()
}
