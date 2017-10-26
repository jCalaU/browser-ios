/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import UIKit
import CoreData
import Foundation
import Shared

class Bookmark: NSManagedObject, WebsitePresentable {
    
    @NSManaged var isFolder: Bool
    @NSManaged var title: String?
    @NSManaged var customTitle: String?
    @NSManaged var url: String?
    @NSManaged var visits: Int32
    @NSManaged var lastVisited: Date?
    @NSManaged var created: Date?
    @NSManaged var order: Int16
    @NSManaged var tags: [String]?
    
    /// Should not be set directly, due to specific formatting required, use `syncUUID` instead
    /// CD does not allow (easily) searching on transformable properties, could use binary, but would still require tranformtion
    //  syncUUID should never change
    @NSManaged var syncDisplayUUID: String?
    @NSManaged var syncParentDisplayUUID: String?
    @NSManaged var parentFolder: Bookmark?
    @NSManaged var children: Set<Bookmark>?
    
    @NSManaged var domain: Domain?
    
    var displayTitle: String? {
        if let custom = customTitle, !custom.isEmpty {
            return customTitle
        }
        
        if let t = title, !t.isEmpty {
            return title
        }
        
        // Want to return nil so less checking on frontend
        return nil
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        created = Date()
        lastVisited = created
    }
    
    static func entity(context:NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: "Bookmark", in: context)!
    }

    class func frc(parentFolder: Bookmark?) -> NSFetchedResultsController<NSFetchRequestResult> {
        let context = DataController.shared.mainThreadContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        
        fetchRequest.entity = Bookmark.entity(context: context)
        fetchRequest.fetchBatchSize = 20
        fetchRequest.sortDescriptors = [NSSortDescriptor(key:"order", ascending: true), NSSortDescriptor(key:"created", ascending: false)]
        if let parentFolder = parentFolder {
            fetchRequest.predicate = NSPredicate(format: "parentFolder == %@", parentFolder)
        } else {
            fetchRequest.predicate = NSPredicate(format: "parentFolder == nil")
        }

        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext:context, sectionNameKeyPath: nil, cacheName: nil)
    }

    class func frecencyQuery(context: NSManagedObjectContext, containing: String?) -> [Bookmark] {
        assert(!Thread.isMainThread)

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.fetchLimit = 5
        fetchRequest.entity = Bookmark.entity(context: context)
        
        var predicate = NSPredicate(format: "lastVisited > %@", History.ThisWeek as CVarArg)
        if let query = containing {
            predicate = NSPredicate(format: predicate.predicateFormat + " AND url CONTAINS %@", query)
        }
        fetchRequest.predicate = predicate

        do {
            if let results = try context.fetch(fetchRequest) as? [Bookmark] {
                return results
            }
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return [Bookmark]()
    }
}

