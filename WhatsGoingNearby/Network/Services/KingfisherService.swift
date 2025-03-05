//
//  KingfisherService.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 05/03/25.
//

import Kingfisher
import UIKit

// Esse Service deve ser usado em todo o App para carregar imagens
// Sua vantagem é que ele armazena imagens em cache
// Isso evita que o usuário gaste dados desnecessariamente
// E melhora a experiência do usuário reduzindo tempos de load

class KingfisherService {
    static let shared = KingfisherService()
    
    private init() {}
    
    func loadImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        
        let resource = KF.ImageResource(downloadURL: url)
        
        do {
            let value = try await KingfisherManager.shared.retrieveImage(with: resource)
            return value.image
        } catch {
            print("Erro ao carregar imagem com Kingfisher: \(error)")
            return nil
        }
    }
}
