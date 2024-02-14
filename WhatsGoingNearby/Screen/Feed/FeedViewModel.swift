//
//  FeedViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import Foundation

class FeedViewModel: ObservableObject {
    
    @Published var posts: [PostData] = []
    @Published var isLoading: Bool = false
    
    func getPostsNearBy() {
        posts = [
            PostData(userProfilePic: "", userName: "Victor Ordozgoite", timestamp: Date(), text: "Alguém sabe quando o KFC vai ser inaugurado?? Já faz tempo que eles estão anunciando...", commentsNumber: 1, likesNumber: 3),
            PostData(userProfilePic: "", userName: "Victor Ordozgoite", timestamp: Date(), text: "Alguém sabe quando o KFC vai ser inaugurado?? Já faz tempo que eles estão anunciando...", commentsNumber: 1, likesNumber: 3),
            PostData(userProfilePic: "", userName: "Victor Ordozgoite", timestamp: Date(), text: "Alguém sabe quando o KFC vai ser inaugurado?? Já faz tempo que eles estão anunciando...", commentsNumber: 1, likesNumber: 3),
            PostData(userProfilePic: "", userName: "Victor Ordozgoite", timestamp: Date(), text: "Alguém sabe quando o KFC vai ser inaugurado?? Já faz tempo que eles estão anunciando...", commentsNumber: 1, likesNumber: 3),
            PostData(userProfilePic: "", userName: "Victor Ordozgoite", timestamp: Date(), text: "Alguém sabe quando o KFC vai ser inaugurado?? Já faz tempo que eles estão anunciando...", commentsNumber: 1, likesNumber: 3),
            PostData(userProfilePic: "", userName: "Victor Ordozgoite", timestamp: Date(), text: "Alguém sabe quando o KFC vai ser inaugurado?? Já faz tempo que eles estão anunciando...", commentsNumber: 1, likesNumber: 3)
        ]
    }
}
