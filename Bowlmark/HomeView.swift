import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: BowlmarkStore
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var activeSheet: BowlmarkSheet?

    var body: some View {
        NavigationStack {
            ZStack {
                BMTheme.backdrop.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            Text("Bowlmark")
                                .font(BMTheme.titleFont)
                                .foregroundStyle(BMTheme.ink)
                            Spacer()
                            Button {
                                if store.canAddPet(isPro: purchases.isPro) {
                                    activeSheet = .addPet
                                } else {
                                    activeSheet = .paywall
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(BMTheme.sage)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("addPetButton")
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 8)

                        if !store.feederLeaderboard.isEmpty {
                            leaderboardCard
                        }

                        if store.pets.isEmpty {
                            emptyState
                        } else {
                            petsList
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addPet:
                    PetFormView(existing: nil)
                case .editPet(let pet):
                    PetFormView(existing: pet)
                case .logFeeding(let pet):
                    LogFeedingView(pet: pet)
                case .paywall:
                    PaywallView()
                }
            }
        }
    }

    /// Quirky signature feature: the "Feeder Leaderboard" — a running
    /// tally of who has fed the most across all pets, all time. Turns
    /// household chore-splitting into a friendly competition.
    private var leaderboardCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FEEDER LEADERBOARD")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.75))
                .tracking(1.0)

            ForEach(Array(store.feederLeaderboard.prefix(3).enumerated()), id: \.offset) { index, entry in
                HStack {
                    Text(medal(for: index))
                        .font(.system(size: 18))
                    Text(entry.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(entry.count) feedings")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .accessibilityIdentifier("leaderboardCard")
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BMTheme.ink)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 18)
    }

    private func medal(for index: Int) -> String {
        switch index {
        case 0: return "1."
        case 1: return "2."
        default: return "3."
        }
    }

    private var petsList: some View {
        VStack(spacing: 12) {
            ForEach(store.pets) { pet in
                PetBowlCard(
                    status: store.status(for: pet),
                    onLogFeeding: { activeSheet = .logFeeding(pet) },
                    onEdit: { activeSheet = .editPet(pet) }
                )
            }
        }
        .padding(.horizontal, 18)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 48))
                .foregroundStyle(BMTheme.inkFaded)
            Text("No pets yet")
                .font(BMTheme.headlineFont)
                .foregroundStyle(BMTheme.ink)
            Text("Add a pet to start tracking who feeds them.")
                .font(.subheadline)
                .foregroundStyle(BMTheme.inkFaded)
        }
        .padding(.top, 24)
        .padding(.horizontal, 18)
    }
}

/// Quirky signature card: a literal bowl that visually fills as meals are
/// logged for the day, draining back to empty at midnight (a new day of
/// entries starts the fill fraction over).
struct PetBowlCard: View {
    let status: PetFeedingStatus
    var onLogFeeding: () -> Void
    var onEdit: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                Button(action: onEdit) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(status.pet.name)
                            .font(BMTheme.headlineFont)
                            .foregroundStyle(BMTheme.ink)
                        Text(status.pet.species)
                            .font(.caption)
                            .foregroundStyle(BMTheme.inkFaded)
                    }
                    .accessibilityElement(children: .combine)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("petNameLabel_\(status.pet.name)")

                Spacer()

                BowlFillView(fraction: status.fillFraction, isFull: status.isFullyFedToday)
                    .frame(width: 56, height: 56)
                    .accessibilityIdentifier("bowlFill_\(status.pet.name)")
                    .accessibilityValue("\(status.mealsLoggedToday) of \(status.pet.mealsPerDay) meals today")
            }

            if let last = status.lastEntry {
                Text("Last fed by \(last.feederName) · \(last.timestamp.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundStyle(BMTheme.inkFaded)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Not fed yet")
                    .font(.caption)
                    .foregroundStyle(BMTheme.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: onLogFeeding) {
                Text("Log Feeding")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(BMTheme.sage)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("logFeedingButton_\(status.pet.name)")
        }
        .padding(14)
        .background(BMTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(BMTheme.rule, lineWidth: 1))
    }
}

struct BowlFillView: View {
    let fraction: Double
    let isFull: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(BMTheme.rule, lineWidth: 4)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(isFull ? BMTheme.sage : BMTheme.butter, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: fraction)

            Image(systemName: isFull ? "checkmark" : "fork.knife")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isFull ? BMTheme.sage : BMTheme.inkFaded)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(BowlmarkStore())
        .environmentObject(PurchaseManager())
}
