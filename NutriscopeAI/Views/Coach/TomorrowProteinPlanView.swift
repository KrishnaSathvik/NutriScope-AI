import SwiftData
import SwiftUI

struct TomorrowProteinPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]

    @State private var eatingOutTomorrow = false
    @State private var addedMealIDs: Set<UUID> = []
    @State private var showAddedToast = false
    @State private var plan: TomorrowPlanCalculator.Plan?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var addingMealID: UUID?

    private var user: UserSettings? { settings.first }
    private var proteinTarget: Int { user?.dailyProteinTarget ?? 135 }
    private var dietPreferences: Set<DietPreference> { user?.dietPreferences ?? [] }
    private var tomorrowLabel: String { TomorrowPlanCalculator.tomorrowLabel() }

    var body: some View {
        BoundedScrollView {

            VStack(alignment: .leading, spacing: 24) {
                headerSection
                eatingOutBanner

                if isLoading {
                    ProgressView("Building tomorrow's plan…")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                } else if let loadError {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Couldn't load plan")
                                .font(AppTypography.headline)
                            Text(loadError)
                                .font(AppTypography.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                            Button("Try again") { Task { await loadPlan() } }
                                .buttonStyle(SecondaryButtonStyle())
                        }
                    }
                } else if let plan {
                    coachRecommendationsSection(plan)
                }
            }
            .padding(AppTheme.marginMain)
            .padding(.bottom, 32)
        
        }
        .background(AppBackground())
        .navigationTitle("Tomorrow's Plan")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if showAddedToast {
                Text("Added to grocery list")
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.proteinTeal)
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35), value: showAddedToast)
        .task { await loadPlan() }
        .onChange(of: eatingOutTomorrow) { _, _ in
            Task { await loadPlan() }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tomorrow's Plan")
                    .font(AppTypography.largeTitle)
                Text("Let's get you ready for \(tomorrowLabel)")
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            HStack(spacing: 0) {
                planStat(
                    label: "Target Protein",
                    value: "\(plan?.targetProtein ?? proteinTarget)",
                    unit: "g",
                    accent: AppTheme.coachOrange
                )
                Divider().frame(height: 48).padding(.horizontal, 8)
                planStat(
                    label: "Planned",
                    value: "\(plan?.plannedProtein ?? 0)",
                    unit: "g",
                    accent: AppTheme.textPrimary
                )
            }
            .padding(16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppTheme.outlineVariant.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: AppTheme.coachOrange.opacity(0.06), radius: 12, y: 4)
        }
    }

    private func planStat(label: String, value: String, unit: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            LabelCapsText(text: label, color: AppTheme.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(accent)
                Text(unit)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var eatingOutBanner: some View {
        SurfaceCard {
            HStack(spacing: 14) {
                Circle()
                    .fill(AppTheme.coachOrange.opacity(0.12))
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(AppTheme.coachOrange)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Eating out tomorrow?")
                        .font(AppTypography.headline)
                    Text("We'll adjust dinner for a flexible restaurant meal.")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer(minLength: 0)

                Toggle("", isOn: $eatingOutTomorrow)
                    .labelsHidden()
                    .tint(AppTheme.coachOrange)
            }
        }
    }

    private func coachRecommendationsSection(_ plan: TomorrowPlanCalculator.Plan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(AppTheme.coachOrange)
                Text("Coach Recommended")
                    .font(AppTypography.title3.weight(.semibold))
            }

            ForEach(plan.meals) { meal in
                tomorrowMealCard(meal)
            }
        }
    }

    private func tomorrowMealCard(_ meal: TomorrowPlanCalculator.MealSuggestion) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.coachOrange.opacity(0.35), AppTheme.warmSun.opacity(0.25), AppTheme.proteinTeal.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 140)
                    .overlay {
                        Image(systemName: meal.systemImage)
                            .font(.system(size: 48))
                            .foregroundStyle(.white.opacity(0.85))
                    }

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.warmSun)
                    LabelCapsText(text: meal.slot.rawValue.uppercased(), color: AppTheme.textPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(12)
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    Text(meal.name)
                        .font(AppTypography.title3.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    VStack(spacing: 2) {
                        Text("\(meal.protein)g")
                            .font(AppTypography.title3.weight(.bold))
                            .foregroundStyle(AppTheme.coachOrange)
                        LabelCapsText(text: "Protein", color: AppTheme.textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.coachOrange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                HStack(spacing: 8) {
                    macroChip("\(meal.calories) kcal")
                    macroChip("\(meal.carbs)g carbs")
                    macroChip("\(meal.fat)g fat")
                }

                if addedMealIDs.contains(meal.id) {
                    Label("Added to list", systemImage: "checkmark.circle.fill")
                        .font(AppTypography.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.proteinTeal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.proteinTeal.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    Button { Task { await addMealToGroceryList(meal) } } label: {
                        if addingMealID == meal.id {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("Add to Shopping List", systemImage: "cart.fill")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(pill: true))
                    .disabled(addingMealID != nil)
                }
            }
            .padding(16)
            .background(AppTheme.surface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppTheme.outlineVariant.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: AppTheme.coachOrange.opacity(0.08), radius: 12, y: 6)
    }

    private func macroChip(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.caption)
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(AppTheme.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func loadPlan() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        do {
            plan = try await OpenAICoachService.buildTomorrowPlan(
                proteinTarget: proteinTarget,
                dietPreferences: dietPreferences,
                eatingOutTomorrow: eatingOutTomorrow,
                tomorrowLabel: tomorrowLabel
            )
        } catch {
            loadError = (error as? LocalizedError)?.errorDescription
                ?? "Add your OpenAI API key in Profile → Developer and try again."
        }
    }

    private func addMealToGroceryList(_ meal: TomorrowPlanCalculator.MealSuggestion) async {
        addingMealID = meal.id
        defer { addingMealID = nil }

        do {
            let items = try await OpenAICoachService.groceryItemsForMeals([meal.name])
            for name in items {
                modelContext.insert(GroceryItem(name: name, category: GroceryCategory.infer(from: name)))
            }
            try? modelContext.save()
            addedMealIDs.insert(meal.id)
            showAddedToast = true
            try? await Task.sleep(for: .seconds(2))
            showAddedToast = false
        } catch {
            loadError = (error as? LocalizedError)?.errorDescription
                ?? "Couldn't add grocery items. Try again."
        }
    }
}

#Preview {
    NavigationStack { TomorrowProteinPlanView() }
        .modelContainer(for: [UserSettings.self, GroceryItem.self], inMemory: true)
}
