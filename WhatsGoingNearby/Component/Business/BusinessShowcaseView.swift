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
                Instagram(usersame: instagramUsername)
            }
        }
    }
    
    // MARK: - Phone
    
    @ViewBuilder
    private func Phone(number: String) -> some View {
        Button {
            // Go to Directions
        } label: {
            Image(systemName: "phone.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28, alignment: .center)
        }
    }
    
    // MARK: - WhatsApp
    
    @ViewBuilder
    private func WhatsApp(number: String) -> some View {
        Button {
            // Go to WhatsApp
        } label: {
            Image("whatsapp")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28, alignment: .center)
        }
    }
    
    // MARK: - Instagram
    
    @ViewBuilder
    private func Instagram(usersame: String) -> some View {
        Button {
            // Go to Instagram
        } label: {
            Image("instagram")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28, alignment: .center)
        }
    }
}

#Preview {
     BusinessShowcaseView(showcase: FormattedBusinessShowcase.mocks[1])
}
