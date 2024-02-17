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
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    //                    HStack(alignment: .top) {
                    //                        VStack {
                    //                            Image(systemName: "person.circle.fill")
                    //                                .resizable()
                    //                                .scaledToFill()
                    //                                .frame(width: 128, height: 128)
                    //                                .clipShape(Circle())
                    //
                    //                            Text(authVM.name)
                    //                                .font(.title)
                    //                                .fontWeight(.medium)
                    //                        }.padding()
                    //
                    //                    }
                    //                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    //                    .listRowInsets(EdgeInsets())
                    
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
                                print("👉 Clicou em deletar conta")
                                Task {
                                    let response = await authVM.deleteAccount()
                                    print("🔴 Response: \(response)")
                                }
                            }
                            .foregroundStyle(.red)
                            Spacer()
                        }
                    } footer: {
                        Text("For account deletions, remember that this action is irreversible.")
                    }
                    
                    //MARK: - Logo
                    
                    //                    VStack {
                    //                        HStack {
                    //                            Spacer()
                    //                            Image(systemName: "location.circle")
                    //                                .resizable()
                    //                                .scaledToFill()
                    //                                .foregroundStyle(.gray)
                    //                                .frame(width: 64, height: 64)
                    //                            Spacer()
                    //                        }
                    //
                    //                        Text("Version 0.1.0")
                    //                            .foregroundStyle(.gray)
                    //                            .fontWeight(.light)
                    //                    }
                    //                    .listRowBackground(colorScheme == .dark ? Color.black : Color.white)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsScreen()
        .environmentObject(AuthenticationViewModel())
}
