import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: BowlmarkStore
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage("bowlmark_reminders_enabled") private var remindersEnabled: Bool = false
    @AppStorage("bowlmark_reminder_hour") private var reminderHour: Int = 18
    @State private var activeSheet: BowlmarkSheet?
    @State private var showResetConfirm = false
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Feeding Reminders") {
                    Toggle("Remind me if a pet hasn't been fed", isOn: $remindersEnabled)
                        .accessibilityIdentifier("remindersToggle")

                    if remindersEnabled {
                        Stepper("Reminder time: \(reminderHour):00", value: $reminderHour, in: 0...23)
                            .accessibilityIdentifier("reminderHourStepper")
                    }
                }

                Section("Bowlmark Pro") {
                    if purchases.isPro {
                        Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(BMTheme.sage)
                    } else {
                        Button("Upgrade to Pro") {
                            activeSheet = .paywall
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("upgradeProButton")
                    }
                    Button("Restore Purchases") {
                        Task {
                            await purchases.restore()
                            restoreMessage = purchases.isPro ? "Purchases restored." : "No purchases found."
                        }
                    }
                    .buttonStyle(.plain)
                    if let restoreMessage {
                        Text(restoreMessage)
                            .font(.caption)
                            .foregroundStyle(BMTheme.inkFaded)
                    }
                }

                Section("About") {
                    Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/bowlmark-site/privacy.html")!)
                    Link("Contact Support", destination: URL(string: "mailto:s0533495227@gmail.com")!)
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(BMTheme.inkFaded)
                    }
                }

                Section {
                    Button("Reset All Data", role: .destructive) {
                        showResetConfirm = true
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Settings")
            .dismissKeyboardOnTap()
            .confirmationDialog(
                "Reset all pets and feeding logs?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    store.deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .paywall:
                    PaywallView()
                default:
                    EmptyView()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(BowlmarkStore())
        .environmentObject(PurchaseManager())
}
