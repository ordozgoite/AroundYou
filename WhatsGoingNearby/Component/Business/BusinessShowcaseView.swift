//
//  BusinessShowcaseView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 26/02/25.
//

import SwiftUI

struct BusinessShowcaseView: View {
    
    let showcase: FormattedBusinessShowcase
    
    private var imageSize: Double {
        return screenWidth * 0.28
    }
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var businessVM: BusinessViewModel
    @State private var isOptionsPopoverDisplayed: Bool = false
    @State private var isReportScreenPresented: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ShowcaseImage()
            
            VStack(alignment: .leading) {
                Header()
                
                Description()
                
                HStack {
                    Location()
                    
                    Spacer()
                    
                    Contacts()
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: imageSize)
        .navigationDestination(isPresented: $isReportScreenPresented) {
            ReportScreen(
                reportedUserUid: showcase.ownerUid,
                publicationId: nil,
                commentId: nil,
                businessId: showcase.id
            )
                .environmentObject(authVM)
        }
    }
    
    // MARK: - Image
    
    @ViewBuilder
    private func ShowcaseImage() -> some View {
        if let imageUrl = showcase.imageUrl {
            URLImageView(imageURL: imageUrl)
                .scaledToFill()
                .frame(width: imageSize, height: imageSize)
                .cornerRadius(8)
                .clipped()
        } else {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(width: imageSize, height: imageSize)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func Header() -> some View {
        HStack {
            Text(showcase.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(systemName: "ellipsis")
                .foregroundStyle(.gray)
                .popover(isPresented: self.$isOptionsPopoverDisplayed) {
                    Options()
                }
                .onTapGesture {
                    self.isOptionsPopoverDisplayed = true
                }
        }
    }
    
    // MARK: - Options
    
    @ViewBuilder
    private func Options() -> some View {
        VStack {
            if showcase.isOwner {
                DeleteButton()
            } else {
                ReportButton()
            }
        }
        .presentationCompactAdaptation(.popover)
    }
    
    // MARK: - Delete Business
    
    @ViewBuilder
    private func DeleteButton() -> some View {
        Button(role: .destructive) {
            Task {
                try await handleBusinessDeletion()
            }
        } label: {
            Text("Delete Business")
            Image(systemName: "trash")
        }
        .padding()
    }
    
    // MARK: - Report Business
    
    @ViewBuilder
    private func ReportButton() -> some View {
        Button {
            isOptionsPopoverDisplayed = false
            isReportScreenPresented = true
        } label: {
            Text("Report Business")
                .foregroundStyle(.gray)
            Image(systemName: "exclamationmark.bubble")
                .foregroundStyle(.gray)
        }
        .padding()
    }
    
    // MARK: - Description
    
    @ViewBuilder
    private func Description() -> some View {
        if let description = showcase.description {
            Text(description)
                .foregroundStyle(.gray)
                .font(.footnote)
                .lineLimit(3)
        }
    }
    
    // MARK: - Location
    
    @ViewBuilder
    private func Location() -> some View {
        HStack {
            if showcase.isLocationVisible {
                Button {
                    // TODO: Go To Maps
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "map")
                        Text("\(String(showcase.distance))m")
                    }
                }
            }
        }
    }
    
    // MARK: - Contacts
    
    @ViewBuilder
    private func Contacts() -> some View {
        HStack {
            if let phoneNumber = showcase.phoneNumber {
                Phone(number: phoneNumber)
            }
            
            if let whatsAppNumber = showcase.whatsAppNumber {
                WhatsApp(number: whatsAppNumber)
            }
            
            if let instagramUsername = showcase.instagramUsername {
                Instagram(username: instagramUsername)
            }
        }
    }
    
    // MARK: - Phone
    
    @ViewBuilder
    private func Phone(number: String) -> some View {
        Button {
            callNumber(number: number)
        } label: {
            Image(systemName: "phone.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28, alignment: .center)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - WhatsApp
    
    @ViewBuilder
    private func WhatsApp(number: String) -> some View {
        Button {
            goToWhatsAppChat(withNumber: number)
        } label: {
            Image("whatsapp")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28, alignment: .center)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Instagram
    
    @ViewBuilder
    private func Instagram(username: String) -> some View {
        Button {
            goToInstagramProfile(forUsername: username)
        } label: {
            Image("instagram")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28, alignment: .center)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Private Methods

extension BusinessShowcaseView {
    private func handleBusinessDeletion() async throws {
        do {
            try await attemptDeletion()
        } catch {
            print("❌ Error trying to delete Business.")
        }
    }
    
    private func attemptDeletion() async throws {
        let token = try await authVM.getFirebaseToken()
        try await businessVM.deleteBusiness(businessId: self.showcase.id, token: token)
    }
    
    private func callNumber(number: String) {
        if let url = URL(string: "tel://\(number.normalizePhoneNumber())"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func goToWhatsAppChat(withNumber number: String) {
        let webURL = URL(string: "https://wa.me/\(number.normalizePhoneNumber())")!
        UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
    }
    
    private func goToInstagramProfile(forUsername username: String) {
        let appURL = URL(string: "instagram://user?username=\(username)")!
        let webURL = URL(string: "https://www.instagram.com/\(username)")!
        
        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        }
    }
}

#Preview {
    BusinessShowcaseView(showcase: FormattedBusinessShowcase.mocks[1], businessVM: BusinessViewModel())
}
