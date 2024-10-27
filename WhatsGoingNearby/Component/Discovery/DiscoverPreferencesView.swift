//
//  DiscoverPreferencesView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/10/24.
//

import SwiftUI
import Sliders

struct DiscoverPreferencesView: View {
    
    @ObservedObject var discoverVM: DiscoverViewModel
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("My Profile")) {
                    TextField("My Display Name", text: $discoverVM.displayName)
                    
                    Picker("Gender", selection: $discoverVM.selectedGender) {
                        ForEach(Gender.allCases) { gender in
                            Text(gender.rawValue.capitalized).tag(gender)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Picker("My Age", selection: $discoverVM.selectedAge) {
                        ForEach(18...99, id: \.self) { age in
                            Text("\(age)").tag(age)
                        }
                    }
                }
                
                Section(header: Text("Preferences")) {
                    Picker("Interested In", selection: $discoverVM.selectedInterestGender) {
                        ForEach(InterestGender.allCases) { interestGender in
                            Text(interestGender.rawValue.capitalized).tag(interestGender)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    VStack {
                        HStack {
                            Text("Age Range")
                            Spacer()
                            Text("From ")
                            +
                            Text("\(Int(discoverVM.ageRange.lowerBound))")
                            +
                            Text(" to ")
                            +
                            Text("\(Int(discoverVM.ageRange.upperBound))")
                        }
                        
                        RangeSlider(range: $discoverVM.ageRange, in: 18...99, step: 1)
                    }
                    .padding(.top)
                    
                    // Interest Age Range Slider
                }
                
                AYButton(title: "Save Preferences") {
                    // Save Preferences
                }
            }
            .navigationTitle("Set Profile")
        }
    }
}

#Preview {
    DiscoverPreferencesView(discoverVM: DiscoverViewModel())
}
