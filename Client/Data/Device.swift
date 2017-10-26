/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import UIKit
import CoreData
import Foundation
import Shared

class Device: NSManagedObject {
    
    // Check if this can be nested inside the method
    private static var sharedCurrentDevice: Device?
    
    // Assign on parent model via CD
    @NSManaged var isSynced: Bool
    
    @NSManaged var created: Date?
    @NSManaged var isCurrentDevice: Bool
    @NSManaged var deviceDisplayId: String?
    @NSManaged var syncDisplayUUID: String?
    @NSManaged var name: String?
    
}
