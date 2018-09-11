//
//  CoreDataImporter.swift
//  JournalCoreData
//
//  Created by Andrew R Madsen on 9/10/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import CoreData

class CoreDataImporter {
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    //Purpose get entry from firebase, check if entries match CoreData,
    //If match, update. If not, create them.
    func sync(entries entryRepresentations: [EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        
        self.context.perform {
            let fetchIdentifiers = entryRepresentations.compactMap {$0.identifier}
            
            let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "identifier IN %@", fetchIdentifiers)
           
            var fetchedEntries: [Entry]? = nil
            do{
                 fetchedEntries = try self.context.fetch(fetchRequest)
            } catch {
                NSLog("Error fetching from context: \(error)")
            }
            guard let entries = fetchedEntries else {return}
            
            let entryDictionary = self.createDictionary(entries: entries)
            
            for entryRep in entryRepresentations {
                guard let identifier = entryRep.identifier else { continue }
                if let entry = entryDictionary[identifier]{
                    if entry != entryRep{
                        self.update(entry: entry, with: entryRep)
                    }
                } else {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }

            }
            completion(nil)
        }
    }
    
    private func createDictionary(entries: [Entry]) -> [String: Entry]{
        var result: [String: Entry] = [:]
        for entry in entries{
            guard let identifier = entry.identifier else {continue}
            result[identifier] = entry
        }
        return result
    }
    
    private func update(entry: Entry, with entryRep: EntryRepresentation) {
        entry.title = entryRep.title
        entry.bodyText = entryRep.bodyText
        entry.mood = entryRep.mood
        entry.timestamp = entryRep.timestamp
        entry.identifier = entryRep.identifier
    }
 
    let context: NSManagedObjectContext
}
