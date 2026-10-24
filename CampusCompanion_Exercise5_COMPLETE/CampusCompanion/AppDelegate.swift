import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    // Build the Core Data schema in Swift. This avoids Xcode's .xcdatamodeld
    // code-generation step while preserving the same persistent entity.
    private static func makeManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let announcement = NSEntityDescription()
        announcement.name = "CampusAnnouncement"
        announcement.managedObjectClassName = NSStringFromClass(CampusAnnouncement.self)

        func stringAttribute(_ name: String, defaultValue: String = "") -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = .stringAttributeType
            attribute.isOptional = false
            attribute.defaultValue = defaultValue
            return attribute
        }

        announcement.properties = [
            stringAttribute("title"),
            stringAttribute("date"),
            stringAttribute("category"),
            stringAttribute("priority", defaultValue: "Normal"),
            stringAttribute("postedBy"),
            stringAttribute("location", defaultValue: "Campus"),
            stringAttribute("priorityLevel", defaultValue: "Normal")
        ]
        model.entities = [announcement]
        return model
    }

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(
            name: "CampusCompanion",
            managedObjectModel: Self.makeManagedObjectModel()
        )
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }
        container.loadPersistentStores { _, error in
            if let error = error {
                // Print the cause for diagnosis and fail clearly during development.
                fatalError("Unresolved Core Data store error: \(error)")
            }
        }
        return container
    }()

    func saveContext() {
        let context = persistentContainer.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Core Data save error: \(error)")
        }
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
