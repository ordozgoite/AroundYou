//
//  DiscoverPreferencesView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/10/24.
//

import SwiftUI
import Sliders

struct DiscoverPreferencesView: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var discoverVM: DiscoverViewModel
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("My Profile"), footer: Text("Edit this info in your profile settings.")) {
                    ProfileInfoView()
                }
                
                Section(footer: Text("We'll match you with people who are interested in your gender and age.")) {
                    GenderView()
                    
                    AgeView()
                }
                
                Section(header: Text("Preferences"), footer: Text("These help us show you people who fit your preferences.")) {
                    InterestGenderView()
                    
                    InterestAgeView()
                }
                
                SaveButtonView()
                
                HideButtonView()
            }
            .onAppear {
                getUserPreferences()
            }
            .navigationTitle("Filters")
        }
    }
    
    //MARK: - Display Name
    
    @ViewBuilder
    private func ProfileInfoView() -> some View {
        HStack {
            ProfilePicView(profilePic: authVM.profilePic, size: 50)
            
            Text(authVM.username)
                .font(.title3)
                .fontWeight(.medium)
        }
        .opacity(0.5)
    }
    
    //MARK: - Gender
    
    @ViewBuilder
    private func GenderView() -> some View {
        VStack(alignment: .leading) {
            Text("I'm a...")
                .font(.title3)
                .fontWeight(.semibold)
            
            GenderPickerView(selectedGender: $discoverVM.selectedGender)
        }
    }
    
    //MARK: - Age
    
    @ViewBuilder
    private func AgeView() -> some View {
        Picker("My Age", selection: $discoverVM.selectedAge) {
            ForEach(18...99, id: \.self) { age in
                Text("\(age)").tag(age)
            }
        }
    }
    
    //MARK: - Interest Gender
    
    @ViewBuilder
    private func InterestGenderView() -> some View {
        VStack(alignment: .leading) {
            Text("I'm interested in...")
                .font(.title3)
                .fontWeight(.semibold)
            
            GenderInterestPickerView(selectedGenders: $discoverVM.selectedInterestGenders)
        }
    }
    
    //MARK: - Interest Age
    
    @ViewBuilder
    private func InterestAgeView() -> some View {
        VStack {
            HStack {
                Text("Age Range")
                Spacer()
                Text("From ")
                +
                Text("**\(Int(discoverVM.ageRange.lowerBound))**")
                    .foregroundColor(.blue)
                +
                Text(" to ")
                +
                Text("**\(Int(discoverVM.ageRange.upperBound))**")
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text("18")
                    .foregroundStyle(.gray)
                RangeSlider(range: $discoverVM.ageRange, in: 18...99, step: 1)
                Text("99")
                    .foregroundStyle(.gray)
            }
        }
        .padding(.top)
    }
    
    //MARK: - Button
    
    @ViewBuilder
    private func SaveButtonView() -> some View {
        if discoverVM.isSettingPreferences {
            AYProgressButton(title: "Saving...")
        } else {
            AYButton(title: "Save Preferences") {
                Task {
                    try await updatePreferences()
                }
            }
            .disabled(!discoverVM.areInputsValid())
        }
    }
    
    //MARK: - Hide Button
    
    @ViewBuilder
    private func HideButtonView() -> some View {
        Section {
            HStack {
                Spacer()
                if discoverVM.isHidingAccount {
                    ProgressView()
                }
                Button(discoverVM.isHidingAccount ? "Hiding Account" : "Hide Account") {
                    Task {
                        try await hideAccount()
                    }
                }
                .disabled(discoverVM.isHidingAccount)
                .foregroundStyle(.red)
                Spacer()
            }
        }
    }
    
    //MARK: - Private Methods
    
    private func updatePreferences() async throws {
        let token = try await authVM.getFirebaseToken()
        await discoverVM.updateUserPreferences(andActivateDiscover: !authVM.isUserDiscoverable, token: token) {
            updateEnvPreferences()
        } updateDiscoverStatus: { isDiscoverable in
            authVM.isUserDiscoverable = isDiscoverable
        }
    }
    
    private func updateEnvPreferences() {
        authVM.isUserDiscoverable = true
        authVM.age = discoverVM.selectedAge
        authVM.gender = discoverVM.selectedGender
        authVM.interestGenders = discoverVM.selectedInterestGenders
        authVM.minInterestAge = Int(discoverVM.ageRange.lowerBound)
        authVM.maxInterestAge = Int(discoverVM.ageRange.upperBound)
    }
    
    private func hideAccount() async throws {
        let token = try await authVM.getFirebaseToken()
        await discoverVM.deactivatedUserDiscoverability(token: token) { isDiscoverable in
            authVM.isUserDiscoverable = isDiscoverable
        }
    }
    
    private func getUserPreferences() {
        print("⚠️ getUserPreferences")
        print("\(authVM.interestGenders)")
        discoverVM.selectedAge = authVM.age
        discoverVM.selectedGender = authVM.gender
        discoverVM.selectedInterestGenders = authVM.interestGenders
        discoverVM.ageRange = Double(authVM.minInterestAge)...Double(authVM.maxInterestAge)
    }
}

#Preview {
    DiscoverPreferencesView(discoverVM: DiscoverViewModel())
        .environmentObject(AuthenticationViewModel())
}
