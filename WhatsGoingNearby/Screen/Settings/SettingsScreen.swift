//
//  SettingsScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct SettingsScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var isDeleteAccountAlertDisplayed: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    
                    //MARK: - Help
                    
                    Section {
                        NavigationLink {
                            BugScreen()
                                .environmentObject(authVM)
                        } label: {
                            Text("Report Bug")
                        }
                    } header: {
                        Text("Help")
                    } footer: {
                        Text("Help us to improve the app we love! If you find any failure, tell us what happened.")
                    }
                    
                    //MARK: - Exit
                    
                    Section {
                        HStack {
                            Spacer()
                            Button("Sign Out") {
                                print("👉 SIGN OUT")
                                authVM.signOut()
                            }
                            .foregroundStyle(.red)
                            Spacer()
                        }
                    }
                    
                    //MARK: - Delete Account
                    Section {
                        HStack {
                            Spacer()
                            Button("Delete Account") {
                                isDeleteAccountAlertDisplayed = true
                            }
                            .foregroundStyle(.red)
                            Spacer()
                        }
                    } footer: {
                        Text("For account deletions, remember that this action is irreversible.")
                    }
                    
                    //MARK: - Logo
                    
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "location.circle")
                                .resizable()
                                .scaledToFill()
                                .foregroundStyle(.gray)
                                .frame(width: 64, height: 64)
                            Spacer()
                        }
                        
                        Text("Version 0.1.0")
                            .foregroundStyle(.gray)
                            .fontWeight(.light)
                    }
                    .listRowBackground(Color(.systemGroupedBackground))
                }
            }
            .alert(isPresented: $isDeleteAccountAlertDisplayed) {
                Alert(
                    title: Text("Account Deletion"),
                    message: Text("Deleting your account is permanent. Are you sure you want to proceed?."),
                    primaryButton: .destructive(Text("Delete")) {
                        Task {
                            let response = await authVM.deleteAccount()
                        }
                    },
                    secondaryButton: .cancel(Text("Cancel")) {}
                )
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsScreen()
        .environmentObject(AuthenticationViewModel())
}
