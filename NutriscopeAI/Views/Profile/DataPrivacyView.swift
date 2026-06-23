import SwiftData
import SwiftUI

struct DataPrivacyView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query private var settings: [UserSettings]
    @Query private var meals: [MealRecord]
    @Query private var weights: [WeightLog]

    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showClearCacheConfirm = false
    @State private var showDeleteAllConfirm = false
    @State private var isDeletingAllData = false
    @State private var cacheClearedMessage: String?

    var body: some View {
        ZStack {
            AppBackground(showsAmbientGlow: true)

            BoundedScrollView {

            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Data & Privacy")
                        .font(AppTypography.headlineLG)
                    Text("Your meal data stays local-first. Export or wipe anytime.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                exportCard
                cacheCard

                ProfileMenuSection(title: "Legal") {
                    policyRow("Privacy Policy", icon: "hand.raised.fill", url: AppLegalLinks.privacyPolicy)
                    ProfileMenuDivider()
                    policyRow("Terms of Use", icon: "doc.text.fill", url: AppLegalLinks.termsOfUse)
                }

                VStack(spacing: 10) {
                    Button("Delete all data", role: .destructive) {
                        showDeleteAllConfirm = true
                    }
                    .font(AppTypography.caption.weight(.bold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .disabled(isDeletingAllData)
                    Text("Permanent — deletes your account (if signed in), meals, settings, and returns to Welcome.")
                        .font(AppTypography.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 8)
            }
            .padding(AppTheme.marginMain)
            .padding(.bottom, 32)
            }
        }
        .navigationTitle("Data & privacy")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
        .kineticConfirmationDialog(
            isPresented: $showClearCacheConfirm,
            icon: "trash.fill",
            title: "Wipe local cache?",
            message: "Remove cached images and temp files. Meals and settings are kept.",
            confirmTitle: "Wipe cache",
            onConfirm: { wipeCache() }
        )
        .kineticConfirmationDialog(
            isPresented: $showDeleteAllConfirm,
            icon: "exclamationmark.triangle.fill",
            iconBackground: AppTheme.warmSun.opacity(0.35),
            iconColor: Color(hex: 0x574500),
            title: "Delete all data?",
            message: "This permanently deletes your account (if signed in), meals, settings, and returns to Welcome. This cannot be undone.",
            confirmTitle: "Delete everything",
            onConfirm: { Task { await deleteAllData() } }
        )
    }

    private var exportCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(AppTheme.coachOrange.opacity(0.12))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(AppTheme.coachOrange)
                        }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Data export")
                            .font(AppTypography.title3.weight(.semibold))
                        Text("Download meals, macros, and profile as JSON.")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                Button("Request data export") { exportData() }
                    .buttonStyle(PrimaryButtonStyle(pill: true))
                Text("Ready immediately on this device.")
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
    }

    private var cacheCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(AppTheme.surfaceMuted)
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "trash")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clear local cache")
                            .font(AppTypography.title3.weight(.semibold))
                        Text("Remove cached images and temp files. Meals and settings are kept.")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                Button("Wipe local cache") { showClearCacheConfirm = true }
                    .buttonStyle(OutlineButtonStyle())
                if let cacheClearedMessage {
                    Text(cacheClearedMessage)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.proteinTeal)
                }
            }
        }
    }

    private func policyRow(_ title: String, icon: String, url: URL) -> some View {
        Button {
            openURL(url)
        } label: {
            ProfileMenuRow(icon: icon, title: title)
        }
        .buttonStyle(.plain)
    }

    private func exportData() {
        do {
            let data = try DataExportService.exportJSON(
                settings: settings.first,
                meals: meals,
                weights: weights
            )
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("nutriscope-export-\(Int(Date().timeIntervalSince1970)).json")
            try data.write(to: url)
            shareItems = [url]
            showShareSheet = true
        } catch {
            cacheClearedMessage = "Export failed. Try again."
        }
    }

    private func wipeCache() {
        URLCache.shared.removeAllCachedResponses()
        ToastCenter.shared.show(
            "Cache Cleared",
            subtitle: "Temp files removed. Meals and settings kept.",
            style: .success
        )
    }

    private func deleteAllData() async {
        isDeletingAllData = true
        defer { isDeletingAllData = false }
        do {
            try await AccountDeletionService.deleteAccount(
                appState: appState,
                modelContext: modelContext
            )
        } catch {
            cacheClearedMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        DataPrivacyView()
            .environment(AppState())
            .modelContainer(for: [UserSettings.self, MealRecord.self, WeightLog.self], inMemory: true)
    }
}
