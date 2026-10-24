import CoreData

@objc(CampusAnnouncement)
public class CampusAnnouncement: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CampusAnnouncement> {
        NSFetchRequest<CampusAnnouncement>(entityName: "CampusAnnouncement")
    }

    @NSManaged public var title: String
    @NSManaged public var date: String
    @NSManaged public var category: String
    @NSManaged public var priority: String
    @NSManaged public var postedBy: String
    @NSManaged public var location: String
    @NSManaged public var priorityLevel: String
}
