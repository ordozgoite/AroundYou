//
//  FormattedBusinessShowcase+Mock.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 26/02/25.
//

import Foundation

extension FormattedBusinessShowcase {
    static let mocks = [
        FormattedBusinessShowcase(
            id: UUID().uuidString,
            imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ16ZTT_mvdBUEmvMsAEjo0Lzo-Hleizud_ig&s",
            title: "Combo Clássico por R$20",
            description: "Peça o seu combo (sanduíche clássico, batata e refri) por apenas R$20,00.\nOferta válida até dia 08/03.",
            category: .eatAndDrink,
            latitude: 0,
            longitude: 0,
            isLocationVisible: true,
            phoneNumber: "+5592982134433",
            whatsAppNumber: "+5592982134433",
            instagramUsername: nil,
            isOwner: false,
            distance: 240,
            ownerUid: UUID().uuidString,
            expirationDate: 1
        ),
        FormattedBusinessShowcase(
            id: UUID().uuidString,
            imageUrl: nil,
            title: "Bicicleta semi-nova R$500",
            description: "Usada por pouco tempo. Preciso me desfazer porque preciso de dinheiro.",
            category: .selling,
            latitude: -3.119027,
            longitude: -60.021731,
            isLocationVisible: false,
            phoneNumber: "+5592982134433",
            whatsAppNumber: nil,
            instagramUsername: nil,
            isOwner: false,
            distance: 333,
            ownerUid: UUID().uuidString,
            expirationDate: 1
        ),
        FormattedBusinessShowcase(
            id: UUID().uuidString,
            imageUrl: "https://example.com/image.jpg",
            title: "Picanha Mania",
            description: "Conheça a melhor picanha de Manaus.",
            category: .eatAndDrink,
            latitude: -3.119027,
            longitude: -60.021731,
            isLocationVisible: false,
            phoneNumber: nil,
            whatsAppNumber: "+5592982134433",
            instagramUsername: "picanhamania",
            isOwner: false,
            distance: 132,
            ownerUid: UUID().uuidString,
            expirationDate: 1
        )
    ]
}
