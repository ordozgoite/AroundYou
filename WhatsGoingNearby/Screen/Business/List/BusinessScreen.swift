//
//  BusinessScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 26/02/25.
//

import SwiftUI

struct BusinessScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var businessVM: BusinessViewModel
    @ObservedObject var locationManager: LocationManager
    
    @State private var refreshObserver = NotificationCenter.default
        .publisher(for: .refreshLocationSensitiveData)
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    if businessVM.isFetchingBusinessesNearBy {
                        LoadingView()
                    } else if businessVM.businesses.isEmpty {
                        EmptyBusinessView()
                    } else {
                        BusinessList()
                    }
                }
                
                AYErrorAlert(message: businessVM.overlayError.1 , isErrorAlertPresented: $businessVM.overlayError.0)
            }
            .onAppear {
                Task {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { try? await getBusinessesFromLocation() }
                        group.addTask { try? await getBusinessesFromUser() }
                    }
                    startUpdatingBusiness()
                }
            }
            .onReceive(refreshObserver) { _ in
                Task {
                    try await getBusinessesFromLocation()
                }
            }
            .onDisappear {
                stopTimer()
            }
//            .navigationTitle("Business")
            .toolbar {
                MyBusiness()
                
                CreateBusinessButton()
            }
        }
    }
    
    //MARK: - Loading
    
    @ViewBuilder
    private func LoadingView() -> some View {
        VStack {
            AYProgressView()
            
            Text("Looking around you...")
                .foregroundStyle(.gray)
                .fontWeight(.semibold)
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    // MARK: - Business List
    
    @ViewBuilder
    private func BusinessList() -> some View {
        List {
            ForEach(businessVM.businesses) { business in
                BusinessShowcaseView(showcase: business, businessVM: businessVM)
                    .environmentObject(authVM)
            }
        }
        .refreshable {
            hapticFeedback(style: .soft)
            businessVM.initialBusinessesFetched = false
            Task {
                try await getBusinessesFromLocation()
            }
        }
    }
    
    // MARK: - My Business
    
    @ViewBuilder
    private func MyBusiness() -> some View {
        Button {
            businessVM.isMyBusinessViewDisplayed = true
        } label: {
            Image(systemName: "person.circle.fill")
        }
        .sheet(isPresented: $businessVM.isMyBusinessViewDisplayed) {
            MyBusinessView(businessVM: businessVM)
                .environmentObject(authVM)
        }
    }
    
    // MARK: - Create Business
    
    @ViewBuilder
    private func CreateBusinessButton() -> some View {
        if businessVM.isFetchingUserBusinesses {
            ProgressView()
        } else if businessVM.userBusinesses?.count != 0 {
            DisabledAddButton()
        } else if businessVM.userBusinesses?.count == 0 {
            AddButton()
        }
    }
    
    // MARK: - Disabled Add Button
    
    @ViewBuilder
    private func DisabledAddButton() -> some View {
        Button {
            businessVM.isBusinessLimitErrorPopoverDisplayed = true
        } label: {
            Image(systemName: "plus")
                .foregroundStyle(.gray)
        }
        .popover(isPresented: $businessVM.isBusinessLimitErrorPopoverDisplayed) {
            Text("You can only have one active Business at a time.")
                .font(.caption)
                .foregroundStyle(.gray)
                .padding()
                .presentationCompactAdaptation(.popover)
        }
    }
    
    // MARK: - Add Button
    
    @ViewBuilder
    private func AddButton() -> some View {
        Button {
            businessVM.isPublishBusinessScreenDisplayed = true
        } label: {
            Image(systemName: "plus")
        }
        .navigationDestination(isPresented: $businessVM.isPublishBusinessScreenDisplayed) {
            PublishBusinessScreen(locationManager: locationManager)
                .environmentObject(authVM)
        }
    }
}

// MARK: - Private Methods

extension BusinessScreen {
    private func startUpdatingBusiness() {
        businessVM.timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task {
                try await getBusinessesFromLocation()
            }
        }
        businessVM.timer?.fire()
    }
    
    private func stopTimer() {
        businessVM.timer?.invalidate()
    }
    
    private func getBusinessesFromLocation() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let token = try await authVM.getFirebaseToken()
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            let currentLocation = Location(latitude: latitude, longitude: longitude)
            
            await businessVM.getBusinesses(fromLocation: currentLocation, token: token)
        }
    }
    
    private func getBusinessesFromUser() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let token = try await authVM.getFirebaseToken()
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            let currentLocation = Location(latitude: latitude, longitude: longitude)
            
            await businessVM.getBusinessByUser(withLocation: currentLocation, token: token)
        }
    }
}

#Preview {
    BusinessScreen(businessVM: BusinessViewModel(), locationManager: LocationManager())
}
