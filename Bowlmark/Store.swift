import Foundation
import Combine

@MainActor
final class BowlmarkStore: ObservableObject {
    @Published private(set) var pets: [Pet] = []
    @Published private(set) var entries: [FeedingEntry] = []

    static let freePetLimit = 2

    private let fileURL: URL
    private let calendar = Calendar.current

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("bowlmark_data.json")
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            try? FileManager.default.removeItem(at: fileURL)
        }
        load()
        if pets.isEmpty {
            seedDefaults()
        }
    }

    private func seedDefaults() {
        pets = [
            Pet(name: "Whiskers", species: "Cat", mealsPerDay: 2),
            Pet(name: "Rex", species: "Dog", mealsPerDay: 2)
        ]
        entries = []
        save()
    }

    func canAddPet(isPro: Bool) -> Bool {
        isPro || pets.count < Self.freePetLimit
    }

    @discardableResult
    func addPet(name: String, species: String, mealsPerDay: Int, isPro: Bool) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, mealsPerDay > 0, canAddPet(isPro: isPro) else { return false }
        pets.append(Pet(name: trimmed, species: species, mealsPerDay: mealsPerDay))
        save()
        return true
    }

    func updatePet(_ id: UUID, name: String, species: String, mealsPerDay: Int) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, mealsPerDay > 0, let idx = pets.firstIndex(where: { $0.id == id }) else { return }
        pets[idx].name = trimmed
        pets[idx].species = species
        pets[idx].mealsPerDay = mealsPerDay
        save()
    }

    func deletePet(_ id: UUID) {
        pets.removeAll { $0.id == id }
        entries.removeAll { $0.petID == id }
        save()
    }

    @discardableResult
    func logFeeding(petID: UUID, feederName: String, note: String = "") -> Bool {
        let trimmed = feederName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, pets.contains(where: { $0.id == petID }) else { return false }
        entries.append(FeedingEntry(petID: petID, feederName: trimmed, note: note))
        save()
        return true
    }

    func deleteEntry(_ id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func deleteAllData() {
        pets = []
        entries = []
        seedDefaults()
    }

    // MARK: - Derived

    func todayEntries(for petID: UUID) -> [FeedingEntry] {
        entries.filter { $0.petID == petID && calendar.isDateInToday($0.timestamp) }
            .sorted { $0.timestamp < $1.timestamp }
    }

    func lastEntry(for petID: UUID) -> FeedingEntry? {
        entries.filter { $0.petID == petID }.max { $0.timestamp < $1.timestamp }
    }

    func status(for pet: Pet) -> PetFeedingStatus {
        PetFeedingStatus(pet: pet, todayEntries: todayEntries(for: pet.id), lastEntry: lastEntry(for: pet.id))
    }

    var allStatuses: [PetFeedingStatus] {
        pets.map { status(for: $0) }
    }

    func recentEntries(for petID: UUID, limit: Int = 20) -> [FeedingEntry] {
        entries.filter { $0.petID == petID }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(limit)
            .map { $0 }
    }

    /// Quirky signature stat: who has fed the most across all pets, all time —
    /// the "Feeder Leaderboard."
    var feederLeaderboard: [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        for e in entries {
            counts[e.feederName, default: 0] += 1
        }
        return counts.map { (name: $0.key, count: $0.value) }.sorted { $0.count > $1.count }
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var pets: [Pet]
        var entries: [FeedingEntry]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            pets = decoded.pets
            entries = decoded.entries
        }
    }

    func save() {
        let snapshot = Snapshot(pets: pets, entries: entries)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
