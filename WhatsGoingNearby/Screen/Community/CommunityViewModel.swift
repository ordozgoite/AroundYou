//
//  CommunityViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 04/02/25.
//

import Foundation

@MainActor
class CommunityViewModel: ObservableObject {
    @Published var communities: [Community] = [
        Community(id: "1", name: "Show Guns N' Roses", imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTdLXpuHHbuLb1QC4u4XkaqR50h4BBEqnJ1Sw&s", description: nil, latitude: 0, longitude: 0, isMember: false, isPrivate: false),
        Community(id: "2", name: "Condomínio Anaíra", imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTkXlQ58pctqQXj92LWf2VVylZh5dYLNCsnzA&s", description: nil, latitude: 0, longitude: 0, isMember: false, isPrivate: true),
        Community(id: "3",name: "Alcoólicos Anônimos", imageUrl: nil, description: nil, latitude: 0, longitude: 0, isMember: false, isPrivate: false),
        Community(id: "4", name: "Caçadores de Pokemon", imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS5-8Chu2Jala7WIXFNYCt4PY78NzZng1MVcw&s", description: nil, latitude: 0, longitude: 0, isMember: false, isPrivate: false)
    ]
    @Published var isLoading: Bool = false
}
