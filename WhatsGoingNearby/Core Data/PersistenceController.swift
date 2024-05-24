//
//  PersistenceController.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/05/24.
//

import Foundation
import CoreData

struct PersistenceController {
    
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        self.container = NSPersistentContainer(name: "WhatsGoingNearby")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let err = error as NSError? {
                print("❌ Error: \(err)")
            }
        }
    }
    
    func save() {
        let context = container.viewContext
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Error trying to save context: \(error)")
        }
    }
}
