import SwiftUI

private enum FoodSearchFilter: String, CaseIterable, Identifiable {
    case highProtein = "High Protein"
    case lowCarb = "Low Carb"
    case vegan = "Vegan"
    case keto = "Keto"

    var id: String { rawValue }
}

private struct CommonFoodPick: Identifiable {
    let id = UUID()
    let name: String
    let protein: Int
}

private enum FoodSearchHistory {
    private static let key = "foodSearchRecent"

    static var recent: [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    static func add(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }
        var items = recent.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        items.insert(trimmed, at: 0)
        UserDefaults.standard.set(Array(items.prefix(8)), forKey: key)
    }
}

struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var results: [USDAFoodItem] = []
    @State private var selectedFood: USDAFoodItem?
    @State private var filter: FoodSearchFilter?
    @State private var isSearching = false
    @State private var errorMessage: String?
    var onSelect: (MealAnalysis) -> Void

    private let commonFoods: [CommonFoodPick] = [
        CommonFoodPick(name: "Greek Yogurt", protein: 10),
        CommonFoodPick(name: "Chicken Breast", protein: 31),
        CommonFoodPick(name: "Eggs", protein: 13),
        CommonFoodPick(name: "Salmon", protein: 25)
    ]

    private var displayedResults: [USDAFoodItem] {
        guard let filter else { return results }
        switch filter {
        case .highProtein:
            return results.sorted { $0.protein > $1.protein }
        case .lowCarb:
            return results.filter { $0.carbs <= 10 }.sorted { $0.protein > $1.protein }
        case .vegan:
            return results.filter {
                let d = $0.description.lowercased()
                return !d.contains("chicken") && !d.contains("beef") && !d.contains("fish") && !d.contains("egg")
            }
        case .keto:
            return results.filter { $0.carbs <= 8 }.sorted { $0.fat > $1.fat }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(showsAmbientGlow: true)

                BoundedScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Find Food")
                        .font(AppTypography.headlineLG)
                        .foregroundStyle(AppTheme.textPrimary)

                    HStack(spacing: 0) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.leading, 16)
                        TextField("Search database…", text: $query)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 10)
                            .submitLabel(.search)
                            .onSubmit { Task { await search() } }
                        if isSearching {
                            ProgressView()
                                .padding(.trailing, 12)
                        } else {
                            Button { Task { await search() } } label: {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(AppTheme.coachOrange)
                            }
                            .padding(.trailing, 12)
                            .disabled(query.trimmingCharacters(in: .whitespaces).count < 2)
                        }
                    }
        .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: AppTheme.cardShadow, radius: 8, y: 3)

                    Text("Try searching \"Grilled Salmon\" or \"Oats\"")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                        .padding(.horizontal, 4)

                    if let selectedFood {
                        selectedFoodCard(selectedFood)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(FoodSearchFilter.allCases) { item in
                                KineticFilterChip(title: item.rawValue, isSelected: filter == item) {
                                    filter = filter == item ? nil : item
                                }
                            }
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.primary)
                    }

                    if results.isEmpty && !isSearching && query.isEmpty {
                        commonFoodsSection
                        recentSearchesSection
                    } else {
                        searchResultsSection
                    }
                }
                .padding(AppTheme.marginMain)
                .padding(.bottom, 32)

            }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private func selectedFoodCard(_ food: USDAFoodItem) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(food.description)
                            .font(AppTypography.title3.weight(.semibold))
                        Text(food.brandName ?? "USDA database")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    LabelCapsText(text: food.servingDescription, color: AppTheme.textTertiary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.surfaceMuted)
                        .clipShape(Capsule())
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    KineticMacroStatCell(label: "Protein", value: "\(food.protein)g", highlight: true)
                    KineticMacroStatCell(label: "Calories", value: "\(food.calories)")
                    KineticMacroStatCell(label: "Fat", value: "\(food.fat)g")
                    KineticMacroStatCell(label: "Carbs", value: "\(food.carbs)g")
                }

                Button {
                    FoodSearchHistory.add(food.description)
                    onSelect(USDAFoodSearchService.makeAnalysis(from: food))
                    dismiss()
                } label: {
                    Label("Log Food", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle(pill: true))
            }
        }
    }

    private var commonFoodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Common High-Protein")
                .font(AppTypography.title3.weight(.semibold))

            ForEach(commonFoods) { food in
                Button {
                    query = food.name
                    Task { await search() }
                } label: {
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppTheme.surfaceMuted)
                            .frame(width: 48, height: 48)
                            .overlay {
                                Image(systemName: "fork.knife")
                                    .foregroundStyle(AppTheme.coachOrange)
                            }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(food.name)
                                .font(AppTypography.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("100g serving")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(food.protein)g")
                                .font(AppTypography.subheadline.weight(.bold))
                                .foregroundStyle(AppTheme.coachOrange)
                            LabelCapsText(text: "Protein", color: AppTheme.textTertiary)
                        }
                    }
                    .padding(14)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: AppTheme.coachOrange.opacity(0.06), radius: 10, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var recentSearchesSection: some View {
        let recent = FoodSearchHistory.recent
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Recent Searches")
                    .font(AppTypography.title3.weight(.semibold))
                ForEach(recent, id: \.self) { term in
                    Button {
                        query = term
                        Task { await search() }
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(AppTheme.textTertiary)
                            Text(term)
                                .font(AppTypography.body)
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !displayedResults.isEmpty {
                Text("Results")
                    .font(AppTypography.title3.weight(.semibold))
            }
            ForEach(displayedResults) { food in
                Button {
                    selectedFood = food
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(food.description)
                                .font(AppTypography.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                                .multilineTextAlignment(.leading)
                            Text("\(food.calories) kcal · \(food.protein)g protein")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: selectedFood?.id == food.id ? "checkmark.circle.fill" : "chevron.right")
                            .foregroundStyle(selectedFood?.id == food.id ? AppTheme.coachOrange : AppTheme.textTertiary)
                    }
                    .padding(14)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                selectedFood?.id == food.id ? AppTheme.coachOrange.opacity(0.4) : AppTheme.surfaceContainerHighest,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func search() async {
        isSearching = true
        errorMessage = nil
        selectedFood = nil
        do {
            results = try await USDAFoodSearchService.search(query: query)
            FoodSearchHistory.add(query)
            if results.isEmpty {
                errorMessage = "No matches. Try a simpler term or add a USDA API key in Profile."
            } else if let first = results.first {
                selectedFood = first
            }
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }
        isSearching = false
    }
}

#Preview {
    FoodSearchView { _ in }
}
