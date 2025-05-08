//
//  ReportDetailScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 30/04/25.
//

import SwiftUI

//let isUserTheVictim: Bool?
// TODO: O que fazer se for o próprio usuário a vítima?

struct ReportDetailScreen: View {
    
    let reportId: String
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var vm = ReportDetailViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                if vm.isLoading {
                   ProgressView()
                } else if let report = vm.reportIncident {
                    Form {
                        if let url = report.imageUrl {
                            URLImageView(imageURL: url)
                                .scaledToFit()
                                .frame(height: 256)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowBackground(Color(.systemGroupedBackground))
                        }
                        
                        Section("Incident Description") {
                            Text(report.description)
                        }
                        
                        if let details = report.humanVictimDetails {
                            Section("Victim Details") {
                                Text(details)
                            }
                        }
                        
                        Section("Location") {
                            MapView(latitude: report.latitude, longitude: report.longitude)
                                .frame(height: 256)
                        }
                    }
                }
                
                AYErrorAlert(message: vm.overlayError.1 , isErrorAlertPresented: $vm.overlayError.0)
            }
            .navigationTitle(vm.reportIncident?.type.title ?? "Report")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    let token = try await authVM.getFirebaseToken()
                    await vm.getReport(withId: self.reportId, token: token)
                }
            }
        }
    }
}

#Preview {
    ReportDetailScreen(reportId: UUID().uuidString)
        .environmentObject(AuthenticationViewModel())
}
