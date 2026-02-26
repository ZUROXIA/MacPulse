import SwiftUI
import MacPulseCore

struct CheckForUpdatesView: View {
    let updateChecker: UpdateChecker

    var body: some View {
        HStack {
            if updateChecker.isChecking {
                ProgressView()
                    .controlSize(.small)
                Text("Checking...")
                    .foregroundStyle(.secondary)
            } else if updateChecker.hasUpdate, let url = updateChecker.downloadURL {
                Link("Update Available: v\(updateChecker.latestVersion ?? "")", destination: url)
            } else {
                Button("Check for Updates") {
                    Task { await updateChecker.check() }
                }
            }
        }
    }
}
