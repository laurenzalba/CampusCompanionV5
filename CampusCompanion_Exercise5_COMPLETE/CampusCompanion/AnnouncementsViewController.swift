import UIKit
import CoreData

private enum RemoteEndpoint {
    // This is the endpoint specified in the Exercise 5 handout.
    static let announcements = URL(string: "https://raw.githubusercontent.com/laurenzalba/CampusCompanionV5/refs/heads/main/announcements.json")!
}

final class AnnouncementsViewController: UITableViewController {
    private var announcements: [CampusAnnouncement] = []
    private var selectedAnnouncement: CampusAnnouncement?
    private var isRefreshing = false
    private var refreshBarButtonItem: UIBarButtonItem?

    private var context: NSManagedObjectContext {
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Campus Announcements"
        tableView.rowHeight = 82
        tableView.estimatedRowHeight = 82

        // Keep the navigation controller's automatic Back button visible.
        // Refresh used to occupy leftBarButtonItem, which hid the Back button.
        navigationItem.leftBarButtonItem = nil
        navigationItem.hidesBackButton = false
        let refreshItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshTapped(_:))
        )
        refreshBarButtonItem = refreshItem
        if let addItem = navigationItem.rightBarButtonItem {
            navigationItem.rightBarButtonItems = [addItem, refreshItem]
        } else {
            navigationItem.rightBarButtonItem = refreshItem
        }

        seedInitialAnnouncementsIfNeeded()
        loadAnnouncements()
    }

    // The supplied JSON is bundled with the app so the project has usable data
    // even if the remote course endpoint is offline or unavailable.
    private func bundledAnnouncementData() throws -> Data {
        guard let url = Bundle.main.url(forResource: "announcements", withExtension: "json") else {
            throw NSError(domain: "CampusCompanion", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "The bundled announcements.json file is missing."])
        }
        return try Data(contentsOf: url)
    }

    private func bundledAnnouncementDTOs() throws -> [AnnouncementDTO] {
        try JSONDecoder().decode([AnnouncementDTO].self, from: bundledAnnouncementData())
    }

    private func seedInitialAnnouncementsIfNeeded() {
        let request: NSFetchRequest<CampusAnnouncement> = CampusAnnouncement.fetchRequest()
        do {
            guard try context.count(for: request) == 0 else { return }
            let sample = try bundledAnnouncementDTOs()
            for dto in sample { _ = makeManagedAnnouncement(from: dto) }
            try context.save()
        } catch {
            context.rollback()
            print("Initial announcement seed error: \(error.localizedDescription)")
        }
    }

    private func makeManagedAnnouncement(from dto: AnnouncementDTO) -> CampusAnnouncement {
        let item = CampusAnnouncement(context: context)
        item.title = dto.title
        item.date = dto.date
        item.category = dto.category
        let resolvedPriority = dto.priorityLevel ?? dto.priority ?? "Normal"
        item.priority = resolvedPriority
        item.priorityLevel = resolvedPriority
        item.location = dto.location ?? "Campus"
        item.postedBy = dto.postedBy ?? dto.category
        return item
    }

    private func parsedDate(_ value: String) -> Date? {
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: value) { return date }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in ["MMMM d, yyyy", "MMM d, yyyy", "yyyy-MM-dd"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }

    private func loadAnnouncements() {
        let request: NSFetchRequest<CampusAnnouncement> = CampusAnnouncement.fetchRequest()
        do {
            announcements = try context.fetch(request)
            announcements.sort { first, second in
                switch (parsedDate(first.date), parsedDate(second.date)) {
                case let (a?, b?): return a < b
                case (nil, nil): return first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
                case (_?, nil): return true
                case (nil, _?): return false
                }
            }
        } catch {
            announcements = []
            print("Fetch error: \(error.localizedDescription)")
        }
        tableView.reloadData()
    }

    @IBAction private func refreshTapped(_ sender: UIBarButtonItem) {
        guard !isRefreshing else { return }
        isRefreshing = true
        sender.isEnabled = false
        fetchAnnouncementsFromServer()
    }

    private func fetchAnnouncementsFromServer() {
        let task = URLSession.shared.dataTask(with: RemoteEndpoint.announcements) { [weak self] data, response, error in
            guard let self = self else { return }

            // Per the laboratory requirements, inspect error, HTTP status, then data.
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.finishRefresh()
                    self.loadBundledSampleAfterRemoteFailure(reason: error.localizedDescription)
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let status = (response as? HTTPURLResponse)?.statusCode
                let message = status.map { "HTTP status \($0)" } ?? "Unexpected server response."
                print("Unexpected server response: \(message)")
                DispatchQueue.main.async {
                    self.finishRefresh()
                    self.loadBundledSampleAfterRemoteFailure(reason: message)
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.finishRefresh()
                    self.showAlert(title: "No Data", message: "The server returned an empty response.")
                }
                return
            }

            if let rawJSON = String(data: data, encoding: .utf8) {
                print("Raw announcements JSON:\n\(rawJSON)")
            }

            do {
                let decoded = try JSONDecoder().decode([AnnouncementDTO].self, from: data)
                print("Decoded \(decoded.count) announcements.")
                DispatchQueue.main.async {
                    self.finishRefresh()
                    self.replaceAnnouncements(with: decoded)
                    self.showAlert(title: "Server Reached",
                                   message: "Received \(data.count) bytes from the announcements endpoint.")
                }
            } catch {
                print("Decoding error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.finishRefresh()
                    self.loadBundledSampleAfterRemoteFailure(reason: "The response could not be decoded as the expected JSON array.")
                }
            }
        }
        task.resume()
    }

    private func finishRefresh() {
        isRefreshing = false
        refreshBarButtonItem?.isEnabled = true
    }

    private func loadBundledSampleAfterRemoteFailure(reason: String) {
        do {
            let bundledData = try bundledAnnouncementData()
            let byteCount = bundledData.count
            if let rawSample = String(data: bundledData, encoding: .utf8) {
                print("Bundled sample JSON:\n\(rawSample)")
            }
            let sample = try JSONDecoder().decode([AnnouncementDTO].self, from: bundledData)
            replaceAnnouncements(with: sample)
            showAlert(title: "Sample JSON Loaded",
                      message: "The remote feed was unavailable (\(reason)). Loaded the bundled sample JSON (\(sample.count) announcements, \(byteCount) bytes) instead.")
        } catch {
            showAlert(title: "Refresh Failed", message: "The remote feed and bundled sample both failed: \(error.localizedDescription)")
        }
    }

    private func replaceAnnouncements(with dtos: [AnnouncementDTO]) {
        let request: NSFetchRequest<CampusAnnouncement> = CampusAnnouncement.fetchRequest()
        do {
            let existing = try context.fetch(request)
            for item in existing { context.delete(item) }
            for dto in dtos { _ = makeManagedAnnouncement(from: dto) }
            try context.save()
            loadAnnouncements()
        } catch {
            context.rollback()
            loadAnnouncements()
            print("Announcement replacement error: \(error.localizedDescription)")
            showAlert(title: "Save Failed", message: "The response was received but could not be saved locally.")
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @IBAction private func addAnnouncementTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "New Announcement", message: "Enter a title and category.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Title" }
        alert.addTextField { $0.placeholder = "Category" }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let self = self, let fields = alert?.textFields, fields.count == 2 else { return }
            let title = (fields[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let category = (fields[1].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty, !category.isEmpty else { return }
            let dto = AnnouncementDTO(title: title,
                                      date: DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none),
                                      category: category,
                                      location: "Campus", priorityLevel: "Normal", postedBy: category)
            _ = self.makeManagedAnnouncement(from: dto)
            do { try self.context.save(); self.loadAnnouncements() }
            catch { self.context.rollback(); self.showAlert(title: "Save Failed", message: error.localizedDescription) }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        announcements.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AnnouncementCell", for: indexPath) as? AnnouncementCell else {
            return UITableViewCell()
        }
        cell.configure(with: announcements[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedAnnouncement = announcements[indexPath.row]
        performSegue(withIdentifier: "ShowAnnouncementDetailSegue", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowAnnouncementDetailSegue",
              let destination = segue.destination as? DetailViewController,
              let announcement = selectedAnnouncement else { return }
        destination.announcement = announcement
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let item = announcements[indexPath.row]
        context.delete(item)
        do {
            try context.save()
            announcements.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        } catch {
            context.rollback()
            loadAnnouncements()
            print("Delete error: \(error.localizedDescription)")
        }
    }
}
