//
//  PersistenceController.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/05/24.
//

import Foundation
import CoreData
import UIKit

/// Imagens locais que o Core Data não deve guardar.
///
/// Rascunho e mensagem em envio carregam bytes de foto. Guardá-los no mesmo store das mensagens o
/// incharia e obrigaria a converter `Data` na main thread a cada leitura — aqui só os nomes de
/// arquivo entram no Core Data, e os bytes ficam em disco.
///
/// Fica em Application Support, e não em Caches, que o sistema pode esvaziar a qualquer momento: um
/// rascunho ou uma mensagem por enviar que somem sozinhos são piores do que não ter guardado nada.
/// Como o conteúdo é reproduzível pelo usuário, é excluído do backup do iCloud.
struct LocalImageStore {

    /// Bytes das fotos anexadas a um rascunho.
    static let drafts = LocalImageStore(namespace: "ChatDrafts")
    /// Bytes das fotos de mensagens que ainda não saíram.
    static let pendingMessages = LocalImageStore(namespace: "PendingMessages")

    /// Pasta de mais alto nível, que separa os usos — um rascunho não pode colidir com uma
    /// mensagem por enviar da mesma conversa.
    let namespace: String

    /// Grava a imagem e devolve o nome do arquivo, ou `nil` se não foi possível escrever.
    ///
    /// A mesma compressão do envio: o que fica guardado não deve ter qualidade melhor do que a
    /// imagem que sairia daqui.
    func write(_ image: UIImage, chatId: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8),
              let directory = directory(chatId: chatId, creatingIfNeeded: true)
        else { return nil }

        let fileName = "\(UUID().uuidString).jpg"

        do {
            try data.write(to: directory.appendingPathComponent(fileName), options: .completeFileProtectionUntilFirstUserAuthentication)
            return fileName
        } catch {
            print("❌ Não foi possível gravar a imagem local: \(error)")
            return nil
        }
    }

    func load(named fileName: String, chatId: String) -> UIImage? {
        guard let directory = directory(chatId: chatId, creatingIfNeeded: false),
              let data = try? Data(contentsOf: directory.appendingPathComponent(fileName))
        else { return nil }

        return UIImage(data: data)
    }

    func delete(named fileName: String, chatId: String) {
        guard let directory = directory(chatId: chatId, creatingIfNeeded: false) else { return }
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(fileName))
    }

    func deleteAll(chatId: String) {
        guard let directory = directory(chatId: chatId, creatingIfNeeded: false) else { return }
        try? FileManager.default.removeItem(at: directory)
    }

    /// Apaga tudo o que este uso guardou, de todas as conversas. Chamado na troca de conta.
    func deleteEverything() {
        guard let root = try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false
        ) else { return }

        try? FileManager.default.removeItem(at: root.appendingPathComponent(namespace, isDirectory: true))
    }

    private func directory(chatId: String, creatingIfNeeded: Bool) -> URL? {
        guard let support = try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        ) else { return nil }

        var directory = support.appendingPathComponent(namespace, isDirectory: true)
            .appendingPathComponent(chatId, isDirectory: true)

        guard creatingIfNeeded else {
            return FileManager.default.fileExists(atPath: directory.path) ? directory : nil
        }

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try? directory.setResourceValues(resourceValues)
            return directory
        } catch {
            print("❌ Não foi possível criar a pasta de imagens locais: \(error)")
            return nil
        }
    }
}

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
        // Os bytes das fotos não estão no Core Data, então o batch delete abaixo não os alcança.
        LocalImageStore.drafts.deleteEverything()
        LocalImageStore.pendingMessages.deleteEverything()

        let context = container.viewContext
        for entity in ["CDMessage", "CDChat", "CDDraft"] {
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
