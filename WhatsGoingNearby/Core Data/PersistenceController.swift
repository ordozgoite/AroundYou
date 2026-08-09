//
//  PersistenceController.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/05/24.
//

import Foundation
import CoreData

/// Pilha do Core Data usada pelo cache local de conversas e mensagens.
///
/// Leitura e escrita acontecem no `viewContext`, na main thread. Os volumes aqui são de
/// dezenas a poucas centenas de registros por conversa, e as gravações saem de pontos que
/// já são `@MainActor` (os view models); um contexto de fundo traria a complexidade de
/// mesclagem sem resolver um gargalo que não existe.
struct PersistenceController {

    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        self.container = NSPersistentContainer(name: "WhatsGoingNearby")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("❌ Core Data não carregou: \(error)")
            }
        }

        // As restrições de unicidade por `id` fazem o upsert falhar sem uma política de
        // mesclagem: com esta, o objeto que estamos gravando vence propriedade a propriedade.
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            print("❌ Core Data não salvou: \(error)")
        }
    }

    /// Apaga tudo o que está em cache. Chamado na troca de conta: as mensagens guardam
    /// `isCurrentUser` já resolvido, então o cache de um usuário não serve para outro.
    func wipe() {
        let context = container.viewContext
        for entity in ["CDMessage", "CDChat"] {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let delete = NSBatchDeleteRequest(fetchRequest: request)
            delete.resultType = .resultTypeObjectIDs

            do {
                let result = try context.execute(delete) as? NSBatchDeleteResult
                let ids = result?.result as? [NSManagedObjectID] ?? []
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: [NSDeletedObjectsKey: ids],
                    into: [context]
                )
            } catch {
                print("❌ Core Data não limpou \(entity): \(error)")
            }
        }
    }
}
