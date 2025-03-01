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
        Image(showcase.testImageName)
            .resizable()
            .scaledToFill()
            .frame(width: imageSize, height: imageSize)
            .cornerRadius(8)
            .clipped()
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
        Text(showcase.description)
            .foregroundStyle(.gray)
            .font(.footnote)
            .lineLimit(3)
    }
    
    // MARK: - Location
    
    @ViewBuilder
    private func Location() -> some View {
        HStack {
            if showcase.isLocationVisible {
                Button {
                    // Go To Maps
                } label: {
                    Label("250m", systemImage: "map")
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

// MARK: - Private Methods

extension BusinessShowcaseView {
//    private func get
}

#Preview {
//    BusinessShowcaseView(showcase: FormattedBusinessShowcase(
//        id: UUID().uuidString,
//        testImageName: "mcdonalds",
//        imageUrl: nil,
//        title: "Combo Clássico por R$20",
//        description: "Peça o seu combo (sanduíche clássico, batata e refri) por apenas R$20,00.\nOferta válida até dia 08/03.",
//        latitude: 0,
//        longitude: 0,
//        isLocationVisible: false,
//        phoneNumber: nil,
//        websiteLink: "https://www.mcdonalds.com.br"
//    ))
}
