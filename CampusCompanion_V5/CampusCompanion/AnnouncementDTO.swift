import Foundation

/// Network-facing value type. Optional fields allow the original three-key JSON
/// supplied with the lab to decode while also supporting Exercise 5 Part 3.
struct AnnouncementDTO: Codable {
    let title: String
    let date: String
    let category: String
    let location: String?
    let priorityLevel: String?
    let priority: String?
    let postedBy: String?

    enum CodingKeys: String, CodingKey {
        case title, date, category, location, priorityLevel, priority, postedBy
        case priorityLevelSnakeCase = "priority_level"
    }

    init(title: String, date: String, category: String,
         location: String? = nil, priorityLevel: String? = nil,
         priority: String? = nil, postedBy: String? = nil) {
        self.title = title
        self.date = date
        self.category = category
        self.location = location
        self.priorityLevel = priorityLevel
        self.priority = priority
        self.postedBy = postedBy
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(String.self, forKey: .date)
        category = try container.decode(String.self, forKey: .category)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        priorityLevel = try container.decodeIfPresent(String.self, forKey: .priorityLevel)
            ?? container.decodeIfPresent(String.self, forKey: .priorityLevelSnakeCase)
        priority = try container.decodeIfPresent(String.self, forKey: .priority)
        postedBy = try container.decodeIfPresent(String.self, forKey: .postedBy)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .date)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(priorityLevel, forKey: .priorityLevel)
        try container.encodeIfPresent(priority, forKey: .priority)
        try container.encodeIfPresent(postedBy, forKey: .postedBy)
    }

}
