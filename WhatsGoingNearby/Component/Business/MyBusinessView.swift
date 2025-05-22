//
//  MyBusinessView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 19/03/25.
//

import SwiftUI

struct MyBusinessView: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var businessVM: BusinessViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                if businessVM.isFetchingUserBusinesses {
                    ProgressView()
                } else if let myBusinesses = businessVM.userBusinesses {
                    if myBusinesses.isEmpty {
                        NoBusinessMessage()
                    } else {
                        MyBusinesses(myBusinesses)
                    }
                }
            }
            .navigationTitle("My Businesses")
        }
    }
    
    // MARK: - No Business
    
    @ViewBuilder
    private func NoBusinessMessage() -> some View {
        Text("You don't have any business published.")
            .bold()
            .foregroundStyle(.gray)
    }
    
    // MARK: - MyBusinesses
    
    @ViewBuilder
    private func MyBusinesses(_ myBusinesses: [FormattedBusinessShowcase]) -> some View {
        List {
            ForEach(myBusinesses) { business in
                VStack {
                    Text(businessVM.getTimeLeftText(forBusiness: business))
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    BusinessShowcaseView(showcase: business, businessVM: businessVM)
                        .environmentObject(authVM)
                }
            }
        }
    }
}

#Preview {
    MyBusinessView(businessVM: BusinessViewModel())
}
