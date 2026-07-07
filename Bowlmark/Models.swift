import Foundation

/// A pet whose feedings are tracked.
struct Pet: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var species: String   // free-text: "Cat", "Dog", etc.
    var mealsPerDay: Int

    init(id: UUID = UUID(), name: String, species: String, mealsPerDay: Int = 2) {
        self.id = id
        self.name = name
        self.species = species
        self.mealsPerDay = mealsPerDay
    }
}

/// A single logged feeding: who fed which pet, and when.
struct FeedingEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var petID: UUID
    var feederName: String
    var timestamp: Date
    var note: String

    init(id: UUID = UUID(), petID: UUID, feederName: String, timestamp: Date = Date(), note: String = "") {
        self.id = id
        self.petID = petID
        self.feederName = feederName
        self.timestamp = timestamp
        self.note = note
    }
}

/// Derived per-pet feeding status for "today."
struct PetFeedingStatus {
    let pet: Pet
    let todayEntries: [FeedingEntry]
    let lastEntry: FeedingEntry?

    var mealsLoggedToday: Int { todayEntries.count }
    var isFullyFedToday: Bool { mealsLoggedToday >= pet.mealsPerDay && pet.mealsPerDay > 0 }
    var fillFraction: Double {
        guard pet.mealsPerDay > 0 else { return 0 }
        return min(1.0, Double(mealsLoggedToday) / Double(pet.mealsPerDay))
    }
}
