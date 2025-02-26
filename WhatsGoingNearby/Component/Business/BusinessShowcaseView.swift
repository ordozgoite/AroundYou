//
//  BusinessShowcaseView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 26/02/25.
//

import SwiftUI

//Foto ✅
//Nome da empresa ✅
//Texto ✅
//Link ou número de celular
//Categoria ✅
//Localização ✅

enum BusinessCategory {
    case food
    case service
    // TODO: completar com demais categorias
}

enum BusinessShowcaseContactMethod {
    case phoneNumber
    case websiteLink
}

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
                    Contact()
                    
                    Spacer()
                    
                    Go()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Image
    
    @ViewBuilder
    private func ShowcaseImage() -> some View {
        Image("mcdonalds")
            .resizable()
            .scaledToFill()
            .frame(width: imageSize, height: imageSize)
            .cornerRadius(8)
            .clipped()
    }
    
    // MARK: - Title
    
    @ViewBuilder
    private func Title() -> some View {
        Text(showcase.showcaseTitle)
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
    
    // MARK: - Contact
    
    @ViewBuilder
    private func Contact() -> some View {
        if let number = showcase.phoneNumber {
            Button {
                // O que fazer?
                // Copiar número de telefone?
                // Adicinar à agenda telefônica?
                // redirecionar ao whatsapp?
            } label: {
                HStack {
                    Image(systemName: "phone.fill")
                    Text("Add Contact")
                        .font(.footnote)
                }
            }
        }
    }
    
    // MARK: - Go
    
    @ViewBuilder
    private func Go() -> some View {
        Button {
            // Go to Directions
        } label: {
            Label("Go!", systemImage: "location.fill")
                .fontWeight(.semibold)
        }
        .buttonStyle(.borderedProminent)
    }
}


#Preview {
    BusinessShowcaseView(showcase: FormattedBusinessShowcase(
        id: UUID().uuidString,
        imageUrl: nil,
        showcaseTitle: "Combo Clássico por R$20",
        description: "Peça o seu combo (sanduíche clássico, batata e refri) por apenas R$20,00.\nOferta válida até dia 08/03.",
        latitude: 0,
        longitude: 0,
        phoneNumber: "+55 (92) 98213-4433",
        websiteLink: "https://www.mcdonalds.com.br"
    ))
}
