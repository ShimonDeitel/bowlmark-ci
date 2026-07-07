import SwiftUI

@main
struct BowlmarkApp: App {
    @StateObject private var store = BowlmarkStore()
    @StateObject private var purchases = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(purchases)
        }
    }
}
