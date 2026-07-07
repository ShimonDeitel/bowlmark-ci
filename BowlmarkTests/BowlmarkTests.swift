import XCTest
@testable import Bowlmark

final class BowlmarkTests: XCTestCase {
    var store: BowlmarkStore!

    @MainActor
    override func setUp() {
        super.setUp()
        store = BowlmarkStore()
        store.deleteAllData()
        for p in store.pets { store.deletePet(p.id) }
    }

    @MainActor
    func testAddPet() {
        let added = store.addPet(name: "Milo", species: "Cat", mealsPerDay: 2, isPro: false)
        XCTAssertTrue(added)
        XCTAssertEqual(store.pets.count, 1)
        XCTAssertEqual(store.pets[0].name, "Milo")
    }

    @MainActor
    func testAddPetRejectsEmptyName() {
        let added = store.addPet(name: "  ", species: "Cat", mealsPerDay: 2, isPro: false)
        XCTAssertFalse(added)
    }

    @MainActor
    func testAddPetRejectsZeroMeals() {
        let added = store.addPet(name: "Milo", species: "Cat", mealsPerDay: 0, isPro: false)
        XCTAssertFalse(added)
    }

    @MainActor
    func testFreeLimitBlocksThirdPet() {
        _ = store.addPet(name: "A", species: "Cat", mealsPerDay: 2, isPro: false)
        _ = store.addPet(name: "B", species: "Dog", mealsPerDay: 2, isPro: false)
        XCTAssertFalse(store.canAddPet(isPro: false))
        let third = store.addPet(name: "C", species: "Bird", mealsPerDay: 1, isPro: false)
        XCTAssertFalse(third)
        XCTAssertEqual(store.pets.count, 2)
    }

    @MainActor
    func testProAllowsUnlimitedPets() {
        _ = store.addPet(name: "A", species: "Cat", mealsPerDay: 2, isPro: true)
        _ = store.addPet(name: "B", species: "Dog", mealsPerDay: 2, isPro: true)
        let third = store.addPet(name: "C", species: "Bird", mealsPerDay: 1, isPro: true)
        XCTAssertTrue(third)
        XCTAssertEqual(store.pets.count, 3)
    }

    @MainActor
    func testUpdatePet() {
        _ = store.addPet(name: "Milo", species: "Cat", mealsPerDay: 2, isPro: false)
        let id = store.pets[0].id
        store.updatePet(id, name: "Milo", species: "Cat", mealsPerDay: 3)
        XCTAssertEqual(store.pets[0].mealsPerDay, 3)
    }

    @MainActor
    func testDeletePetAlsoDeletesEntries() {
        _ = store.addPet(name: "Milo", species: "Cat", mealsPerDay: 2, isPro: false)
        let id = store.pets[0].id
        store.logFeeding(petID: id, feederName: "Alex")
        XCTAssertEqual(store.entries.count, 1)
        store.deletePet(id)
        XCTAssertTrue(store.pets.isEmpty)
        XCTAssertTrue(store.entries.isEmpty)
    }

    @MainActor
    func testLogFeeding() {
        _ = store.addPet(name: "Milo", species: "Cat", mealsPerDay: 2, isPro: false)
        let id = store.pets[0].id
        let logged = store.logFeeding(petID: id, feederName: "Alex", note: "half portion")
        XCTAssertTrue(logged)
        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries[0].feederName, "Alex")
    }

    @MainActor
    func testLogFeedingRejectsEmptyFeederName() {
        _ = store.addPet(name: "Milo", species: "Cat", mealsPerDay: 2, isPro: false)
        let id = store.pets[0].id
        let logged = store.logFeeding(petID: id, feederName: "  ")
        XCTAssertFalse(logged)
    }

    @MainActor
    func testLogFeedingRejectsUnknownPet() {
        let logged = store.logFeeding(petID: UUID(), feederName: "Alex")
        XCTAssertFalse(logged)
        XCTAssertTrue(store.entries.isEmpty)
    }

    @MainActor
    func testDeleteEntry() {
        _ = store.addPet(name: "Milo", species: "Cat", mealsPerDay: 2, isPro: false)
        let id = store.pets[0].id
        store.logFeeding(petID: id, feederName: "Alex")
        let entryID = store.entries[0].id
        store.deleteEntry(entryID)
        XCTAssertTrue(store.entries.isEmpty)
    }

    @MainActor
    func testStatusFillFraction() {
        _ = store.addPet(name: "Milo", species: "Cat", mealsPerDay: 2, isPro: false)
        let pet = store.pets[0]
        XCTAssertEqual(store.status(for: pet).fillFraction, 0)
        store.logFeeding(petID: pet.id, feederName: "Alex")
        XCTAssertEqual(store.status(for: pet).fillFraction, 0.5, accuracy: 0.001)
        store.logFeeding(petID: pet.id, feederName: "Sam")
        XCTAssertEqual(store.status(for: pet).fillFraction, 1.0, accuracy: 0.001)
        XCTAssertTrue(store.status(for: pet).isFullyFedToday)
    }

    @MainActor
    func testFeederLeaderboardCounts() {
        _ = store.addPet(name: "Milo", species: "Cat", mealsPerDay: 3, isPro: true)
        _ = store.addPet(name: "Rex", species: "Dog", mealsPerDay: 2, isPro: true)
        let milo = store.pets[0].id
        let rex = store.pets[1].id
        store.logFeeding(petID: milo, feederName: "Alex")
        store.logFeeding(petID: rex, feederName: "Alex")
        store.logFeeding(petID: milo, feederName: "Sam")
        let board = store.feederLeaderboard
        XCTAssertEqual(board.first?.name, "Alex")
        XCTAssertEqual(board.first?.count, 2)
    }

    @MainActor
    func testLastEntryReturnsMostRecent() {
        _ = store.addPet(name: "Milo", species: "Cat", mealsPerDay: 2, isPro: false)
        let id = store.pets[0].id
        store.logFeeding(petID: id, feederName: "Alex")
        store.logFeeding(petID: id, feederName: "Sam")
        XCTAssertEqual(store.lastEntry(for: id)?.feederName, "Sam")
    }

    @MainActor
    func testDeleteAllDataReseeds() {
        _ = store.addPet(name: "Extra", species: "Bird", mealsPerDay: 1, isPro: true)
        store.deleteAllData()
        XCTAssertFalse(store.pets.isEmpty)
    }
}
