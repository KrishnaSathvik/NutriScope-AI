import SwiftData
import SwiftUI

struct RecipeCalculatorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]

    @State private var recipeName = ""
    @State private var servings = 2
    @State private var quickAddLine = ""
    @State private var ingredients: [RecipeMacroCalculator.Ingredient] = []
    @State private var didSaveMeal = false

    private var totals: RecipeMacroCalculator.Totals {
        RecipeMacroCalculator.totals(for: ingredients, servings: servings)
    }

    private var proteinTarget: Int { settings.first?.dailyProteinTarget ?? 135 }

    var body: some View {
        BoundedScrollView {

            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .bottom) {
                    TextField("Recipe name (e.g., Chicken Prep)", text: $recipeName)
                        .font(AppTypography.title3)
                        .padding(14)
                        .background(AppTheme.surfaceMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    servingsStepper
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Ingredients")
                            .font(AppTypography.title3.weight(.semibold))
                        Spacer()
                        if !ingredients.isEmpty {
                            Text("\(ingredients.count) ITEMS")
                                .font(AppTypography.labelCaps)
                                .foregroundStyle(AppTheme.coachOrange)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppTheme.coachOrange.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    if ingredients.isEmpty {
                        KineticEmptyState(
                            systemImage: "frying.pan",
                            title: "No ingredients yet",
                            message: "Add items with calories and protein to see batch totals."
                        )
                    } else {
                        ForEach(ingredients) { item in
                            KineticIngredientRow(
                                name: item.name,
                                detail: "Per batch",
                                macroHighlight: "\(item.protein)g P",
                                calories: "\(item.calories) kcal",
                                icon: ingredientIcon(for: item.name)
                            ) {
                                ingredients.removeAll { $0.id == item.id }
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        TextField("Ingredient + macros (e.g. chicken, cal 165 protein 31)", text: $quickAddLine)
                            .padding(14)
                            .background(AppTheme.surfaceMuted)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Button("Add") { addIngredient() }
                            .buttonStyle(SecondaryButtonStyle())
                    }

                    Button { addIngredient() } label: {
                        Label("Add Ingredient", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(OutlineButtonStyle())
                    .disabled(quickAddLine.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(16)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: AppTheme.coachOrange.opacity(0.06), radius: 12, y: 4)

                if !ingredients.isEmpty, let per = totals.perServing {
                    perServingDashboard(per: per)
                    batchTotalsCard
                }

                if !ingredients.isEmpty {
                    Button("Save as Meal") { saveAsMeal() }
                        .buttonStyle(PrimaryButtonStyle(pill: true))
                    if didSaveMeal {
                        Label("Recipe saved to meal log", systemImage: "checkmark.circle.fill")
                            .font(AppTypography.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.proteinTeal)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(AppTheme.marginMain)
            .padding(.bottom, 32)
        
        }
        .background(AppBackground())
        .navigationTitle("Recipe calculator")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var servingsStepper: some View {
        HStack(spacing: 10) {
            LabelCapsText(text: "Servings", color: AppTheme.textSecondary)
            Button { servings = max(1, servings - 1) } label: {
                Image(systemName: "minus")
                    .frame(width: 32, height: 32)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            Text("\(servings)")
                .font(AppTypography.title3.weight(.bold))
                .frame(width: 28)
            Button { servings = min(12, servings + 1) } label: {
                Image(systemName: "plus")
                    .frame(width: 32, height: 32)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func perServingDashboard(per: RecipeMacroCalculator.TotalsPerServing) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        LabelCapsText(text: "Per Serving", color: AppTheme.textTertiary)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(per.calories)")
                                .font(.system(size: 34, weight: .heavy, design: .rounded))
                            Text("kcal")
                                .font(AppTypography.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        LabelCapsText(text: "Protein Focus", color: AppTheme.proteinTeal)
                        Text("\(per.protein)g")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.proteinTeal)
                    }
                }

                KineticMacroProgressBar(
                    label: "Protein",
                    value: "\(per.protein)g / \(proteinTarget / max(servings, 1))g goal",
                    progress: Double(per.protein) / Double(max(proteinTarget / max(servings, 1), 1)),
                    color: AppTheme.proteinTeal,
                    thick: true
                )
                KineticMacroProgressBar(
                    label: "Carbs",
                    value: "\(per.carbs)g",
                    progress: min(Double(per.carbs) / 80, 1),
                    color: AppTheme.warmSun
                )
                KineticMacroProgressBar(
                    label: "Fats",
                    value: "\(per.fat)g",
                    progress: min(Double(per.fat) / 40, 1),
                    color: AppTheme.fat
                )
            }
        }
    }

    private var batchTotalsCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                LabelCapsText(text: "Batch Totals (\(servings) servings)", color: AppTheme.textTertiary)
                HStack {
                    batchStat(label: "Cals", value: "\(totals.calories)")
                    batchStat(label: "Pro", value: "\(totals.protein)g", accent: AppTheme.proteinTeal)
                    batchStat(label: "Carb", value: "\(totals.carbs)g", accent: AppTheme.warmSun)
                    batchStat(label: "Fat", value: "\(totals.fat)g")
                }
            }
        }
    }

    private func batchStat(label: String, value: String, accent: Color = AppTheme.textPrimary) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.textTertiary)
            Text(value)
                .font(AppTypography.subheadline.weight(.bold))
                .foregroundStyle(accent)
        }
        .frame(maxWidth: .infinity)
    }

    private func ingredientIcon(for name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("chicken") || lower.contains("fish") { return "fork.knife" }
        if lower.contains("rice") || lower.contains("oat") { return "leaf" }
        if lower.contains("oil") || lower.contains("butter") { return "drop" }
        return "carrot"
    }

    private func addIngredient() {
        guard let ingredient = RecipeMacroCalculator.parseQuickAdd(quickAddLine) else { return }
        ingredients.append(ingredient)
        quickAddLine = ""
    }

    private func saveAsMeal() {
        guard let per = totals.perServing else { return }
        let name = recipeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let mealName = name.isEmpty ? "Custom Recipe" : name
        let analysis = MealAnalysis(
            mealName: mealName,
            calories: MacroRange(min: per.calories, max: per.calories),
            protein: MacroRange(min: per.protein, max: per.protein),
            carbs: MacroRange(min: per.carbs, max: per.carbs),
            fat: MacroRange(min: per.fat, max: per.fat),
            confidence: .high,
            followUpQuestions: [],
            advice: MealAdvice(
                headline: "Recipe logged",
                proteinGapGrams: max(0, proteinTarget - per.protein),
                suggestions: [],
                coachMessage: "Saved from recipe calculator — one serving logged.",
                balanceScore: 70
            )
        )
        modelContext.insert(MealRecord(from: analysis, mealNote: "Recipe · \(servings) servings batch", mealType: .dinner))
        try? modelContext.save()
        didSaveMeal = true
    }
}

#Preview {
    NavigationStack { RecipeCalculatorView() }
        .modelContainer(for: [UserSettings.self, MealRecord.self], inMemory: true)
}
