import SwiftUI

enum BowlmarkSheet: Identifiable {
    case addPet
    case editPet(Pet)
    case logFeeding(Pet)
    case paywall

    var id: String {
        switch self {
        case .addPet: return "addPet"
        case .editPet(let p): return "edit-\(p.id)"
        case .logFeeding(let p): return "log-\(p.id)"
        case .paywall: return "paywall"
        }
    }
}

struct PetFormView: View {
    @EnvironmentObject private var store: BowlmarkStore
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    let existing: Pet?

    @State private var name: String
    @State private var species: String
    @State private var mealsPerDay: Int

    init(existing: Pet?) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _species = State(initialValue: existing?.species ?? "Cat")
        _mealsPerDay = State(initialValue: existing?.mealsPerDay ?? 2)
    }

    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Pet") {
                    TextField("Name (e.g. Whiskers)", text: $name)
                        .accessibilityIdentifier("petNameField")

                    TextField("Species (e.g. Cat, Dog)", text: $species)
                        .accessibilityIdentifier("petSpeciesField")

                    HStack {
                        Text("Meals per day: \(mealsPerDay)")
                        Spacer()
                        Button {
                            if mealsPerDay > 1 { mealsPerDay -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("mealsDecrementButton")

                        Button {
                            if mealsPerDay < 8 { mealsPerDay += 1 }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("mealsIncrementButton")
                    }
                }

                if isEditing {
                    Section {
                        Button("Delete Pet", role: .destructive) {
                            if let existing {
                                store.deletePet(existing.id)
                            }
                            dismiss()
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("deletePetButton")
                    }
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle(isEditing ? "Edit Pet" : "New Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        if isEditing, let existing {
                            store.updatePet(existing.id, name: name, species: species, mealsPerDay: mealsPerDay)
                        } else {
                            store.addPet(name: name, species: species, mealsPerDay: mealsPerDay, isPro: purchases.isPro)
                        }
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("savePetButton")
                }
            }
        }
    }
}

struct LogFeedingView: View {
    @EnvironmentObject private var store: BowlmarkStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("bowlmark_last_feeder_name") private var lastFeederName: String = ""

    let pet: Pet

    @State private var feederName: String = ""
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Who fed \(pet.name)?") {
                    TextField("Your name", text: $feederName)
                        .accessibilityIdentifier("feederNameField")
                }
                Section("Note (optional)") {
                    TextField("e.g. half portion", text: $note)
                        .accessibilityIdentifier("feedingNoteField")
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle("Log Feeding")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if feederName.isEmpty { feederName = lastFeederName }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        lastFeederName = feederName
                        store.logFeeding(petID: pet.id, feederName: feederName, note: note)
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .disabled(feederName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("saveLogFeedingButton")
                }
            }
        }
    }
}
