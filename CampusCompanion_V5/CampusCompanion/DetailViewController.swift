import UIKit

final class DetailViewController: UIViewController {
    @IBOutlet private weak var messageLabel: UILabel!

    var studentName: String = "Student"
    var notificationsEnabled: Bool = false
    var selectedRole: String = "Student"
    var preferredEventDate: Date = Date()
    var numberOfGuests: Int = 1
    var announcement: CampusAnnouncement?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let announcement = announcement {
            title = announcement.category
            messageLabel.text = "\(announcement.title)\n\nCategory: \(announcement.category)\nDate: \(announcement.date)\nLocation: \(announcement.location)\nPriority Level: \(announcement.priorityLevel)\nPosted By: \(announcement.postedBy)"
        } else {
            title = "Campus Events"
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            let dateText = formatter.string(from: preferredEventDate)
            let notificationStatus = notificationsEnabled ? "on" : "off"
            messageLabel.text = "Welcome, \(studentName)! (\(selectedRole))\nNotifications: \(notificationStatus).\nEvent: \(dateText)\nGuests: \(numberOfGuests)"
        }
    }
}
