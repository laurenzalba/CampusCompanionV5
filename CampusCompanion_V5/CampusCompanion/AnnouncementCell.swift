import UIKit

final class AnnouncementCell: UITableViewCell {
    @IBOutlet private weak var categoryIconImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var priorityLabel: UILabel!

    func configure(with announcement: CampusAnnouncement) {
        titleLabel.text = announcement.title
        dateLabel.numberOfLines = 2
        dateLabel.text = "\(announcement.category) • \(announcement.date)\nLocation: \(announcement.location)"

        let priority = announcement.priorityLevel.isEmpty ? announcement.priority : announcement.priorityLevel
        priorityLabel.text = priority
        let isUrgent = priority.caseInsensitiveCompare("urgent") == .orderedSame
        categoryIconImageView.image = UIImage(systemName: isUrgent ? "exclamationmark.triangle.fill" : "megaphone.fill")
        categoryIconImageView.tintColor = isUrgent ? .systemRed : .systemBlue
        priorityLabel.textColor = isUrgent ? .systemRed : .secondaryLabel
        accessoryType = .disclosureIndicator
    }
}
