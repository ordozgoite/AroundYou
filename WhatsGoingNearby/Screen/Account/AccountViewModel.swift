//
//  AccountViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/02/24.
//

import Foundation

class AccountViewModel: ObservableObject {
    
    @Published var posts: [FormattedPost] = []
    @Published var newBioTextInput: String = ""
    @Published var isEditBioAlertPresented: Bool = false
    
    func getUserPosts() async {
        
    }
    
    func editBio(bio: String, token: String, updateBio: (String) -> ()) async {
        newBioTextInput = ""
        let response = await AYServices.shared.editBiography(biography: bio, token: token)
        
        switch response {
        case .success:
            updateBio(bio)
        case .failure(let error):
            // Display error
            print("❌ Error: \(error)")
        }
    }
}
