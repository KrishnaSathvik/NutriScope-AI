import SwiftData
import SwiftUI

struct GroceryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GroceryItem.createdAt, order: .reverse) private var items: [GroceryItem]
    @Query private var settings: [UserSettings]
    @Query(sort: \MealRecord.scannedAt, order: .reverse) private var meals: [MealRecord]

    @State private var newItemName = ""
    @State private var coachGapSuggestions: [String] = []
    @State private var isLoadingSuggestions = false
    @State private var isGeneratingList = false
    @State private var suggestionError: String?

    private var unchecked: [GroceryItem] { items.filter { !$0.isChecked } }
    private var checked: [GroceryItem] { items.filter { $0.isChecked } }
    private var proteinGap: Int {
        let target = settings.first?.dailyProteinTarget ?? 135
        let todayProtein = meals
            .filter { Calendar.current.isDateInToday($0.scannedAt) }
            .reduce(0) { $0 + $1.proteinMidpoint }
        return max(0, target - todayProtein)
    }

    private var displayedGapSuggestions: [String] {
        Array(coachGapSuggestions.prefix(3))
    }

    private var checkoutProgress: Double {
        guard !items.isEmpty else { return 0 }
        return Double(checked.count) / Double(items.count)
    }

    var body: some View {
        BoundedScrollView {

            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Grocery List")
                            .font(AppTypography.largeTitle)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Tools to help you hit your targets.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    Button { Task { await generateFromCoach() } } label: {
                        Image(systemName: "plus")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AppTheme.coachOrange)
                            .frame(width: 48, height: 48)
                            .background(AppTheme.coachOrange.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                if proteinGap > 0 {
                    gapSuggestionsCard
                }

                if !items.isEmpty {
                    summaryCard
                }

                if items.isEmpty {
                    groceryEmptyState
                } else {
                    listSection
                }

                quickAddField
            }
            .padding(AppTheme.marginMain)
            .padding(.bottom, 32)
        
        }
        .background(AppBackground())
        .navigationTitle("Grocery list")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadGapSuggestions() }
        .onChange(of: proteinGap) { _, _ in Task { await loadGapSuggestions() } }
    }

    private var gapSuggestionsCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(AppTheme.coachOrange)
                        .padding(8)
                        .background(AppTheme.coachOrange.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Text("Suggested for your Protein Gap")
                        .font(AppTypography.title3.weight(.semibold))
                }
                Text("You're short \(proteinGap)g of protein today. Tap to add to your list.")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                if isLoadingSuggestions {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if let suggestionError {
                    Text(suggestionError)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    ForEach(displayedGapSuggestions, id: \.self) { suggestion in
                    Button {
                        addNamedItem(suggestion)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion)
                                    .font(AppTypography.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text("High protein pick")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppTheme.coachOrange)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(AppTheme.coachOrange)
                        }
                        .padding(12)
                        .background(AppTheme.surfaceMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var summaryCard: some View {
        SurfaceCard {
            VStack(spacing: 10) {
                Image(systemName: "cart.fill")
                    .font(.title)
                    .foregroundStyle(AppTheme.coachOrange)
                Text("\(items.count) Items")
                    .font(AppTypography.title2.weight(.bold))
                Text("\(unchecked.count) left to buy")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(AppTheme.surfaceMuted)
                        Capsule()
                            .fill(AppTheme.coachOrange)
                            .frame(width: geo.size.width * checkoutProgress)
                    }
                }
                .frame(height: 8)
                HStack {
                    LabelCapsText(text: "Checked off", color: AppTheme.textSecondary)
                    Spacer()
                    Text("\(Int(checkoutProgress * 100))%")
                        .font(AppTypography.labelCaps)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var groceryEmptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.coachOrange.opacity(0.12))
                    .frame(width: 128, height: 128)
                    .blur(radius: 20)
                Circle()
                    .fill(AppTheme.surface)
                    .frame(width: 96, height: 96)
                    .overlay {
                        Image(systemName: "basket.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(AppTheme.coachOrange.opacity(0.7))
                    }
                    .shadow(color: AppTheme.coachOrange.opacity(0.12), radius: 12, y: 6)
            }
            Text("Your list is empty")
                .font(AppTypography.title2.weight(.bold))
            Text("Add high-protein meals from coach suggestions or add items manually.")
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button("Suggest from protein gap") { Task { await generateFromCoach() } }
                .buttonStyle(PrimaryButtonStyle(pill: true))
                .disabled(isGeneratingList)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var listSection: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Your List")
                        .font(AppTypography.title3.weight(.semibold))
                    Spacer()
                    if !checked.isEmpty {
                        Button("Clear checked") { clearChecked() }
                            .font(AppTypography.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.coachOrange)
                    }
                }

                if !unchecked.isEmpty {
                    ForEach(unchecked, id: \.id) { item in
                        groceryRow(item)
                    }
                }
                if !checked.isEmpty {
                    Text("Done")
                        .font(AppTypography.caption.weight(.bold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.top, 4)
                    ForEach(checked, id: \.id) { item in
                        groceryRow(item)
                    }
                }
            }
        }
    }

    private var quickAddField: some View {
        HStack(spacing: 10) {
            HStack {
                Image(systemName: "plus")
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("Add custom item…", text: $newItemName)
                    .submitLabel(.done)
                    .onSubmit { addItem() }
            }
            .padding(14)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            Button("Add") { addItem() }
                .buttonStyle(SecondaryButtonStyle())
        }
    }

    private func groceryRow(_ item: GroceryItem) -> some View {
        Button {
            item.isChecked.toggle()
            try? modelContext.save()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.isChecked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(item.isChecked ? AppTheme.coachOrange : AppTheme.textTertiary)
                Text(item.name)
                    .font(AppTypography.body)
                    .foregroundStyle(item.isChecked ? AppTheme.textSecondary : AppTheme.textPrimary)
                    .strikethrough(item.isChecked)
                Spacer()
                categoryBadge(item.category)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func categoryBadge(_ category: GroceryCategory) -> some View {
        let color: Color = switch category {
        case .protein: AppTheme.coachOrange
        case .produce: AppTheme.proteinTeal
        case .dairy: AppTheme.warmSun
        case .pantry, .other: AppTheme.textSecondary
        }
        return Text(category.label.uppercased())
            .font(AppTypography.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func addItem() {
        let trimmed = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        addNamedItem(trimmed)
        newItemName = ""
    }

    private func addNamedItem(_ name: String) {
        guard !items.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else { return }
        modelContext.insert(GroceryItem(name: name, category: GroceryCategory.infer(from: name)))
        try? modelContext.save()
    }

    private func loadGapSuggestions() async {
        guard proteinGap > 0 else {
            coachGapSuggestions = []
            return
        }

        isLoadingSuggestions = true
        suggestionError = nil
        defer { isLoadingSuggestions = false }

        do {
            coachGapSuggestions = try await OpenAICoachService.grocerySuggestions(
                proteinGap: proteinGap,
                dietPreferences: settings.first?.dietPreferences ?? []
            )
        } catch {
            coachGapSuggestions = []
            suggestionError = (error as? LocalizedError)?.errorDescription
        }
    }

    private func generateFromCoach() async {
        isGeneratingList = true
        defer { isGeneratingList = false }

        do {
            let names: [String]
            if coachGapSuggestions.isEmpty {
                names = try await OpenAICoachService.grocerySuggestions(
                    proteinGap: proteinGap,
                    dietPreferences: settings.first?.dietPreferences ?? []
                )
                coachGapSuggestions = names
            } else {
                names = coachGapSuggestions
            }
            for name in names {
                addNamedItem(name)
            }
        } catch {
            suggestionError = (error as? LocalizedError)?.errorDescription
        }
    }

    private func clearChecked() {
        for item in checked {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack { GroceryListView() }
        .modelContainer(for: [GroceryItem.self, UserSettings.self, MealRecord.self], inMemory: true)
}
