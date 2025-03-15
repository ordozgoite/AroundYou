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
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ShowcaseImage()
            
            VStack(alignment: .leading) {
                Title()
                
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
    
    // MARK: - Title
    
    @ViewBuilder
    private func Title() -> some View {
        Text(showcase.title)
            .fontWeight(.bold)
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
                    // Go To Maps
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "map")
                        Text("250m") // TODO: change value programatically
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
    BusinessShowcaseView(showcase: FormattedBusinessShowcase.mocks[1])
}
