import SwiftUI

struct PostScanSuccessView: View {
    let mealName: String
    let mealType: MealType
    let protein: Int
    let calories: Int
    var onViewToday: () -> Void
    var onLogAnother: () -> Void
    var onDismiss: () -> Void

    @State private var bounce = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            KineticConfettiView()
                .allowsHitTesting(false)

            BoundedScrollView {

                VStack(spacing: 24) {
                    successHeader
                    summaryCard
                    actionButtons
                }
                .padding(.horizontal, AppTheme.marginMain)
                .padding(.vertical, 32)
            
        }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) {
                bounce = true
            }
        }
    }

    private var successHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.proteinTeal.opacity(0.12))
                    .frame(width: 96, height: 96)
                    .scaleEffect(bounce ? 1 : 0.6)
                    .opacity(bounce ? 1 : 0)
                Circle()
                    .stroke(AppTheme.proteinTeal.opacity(0.25), lineWidth: 2)
                    .frame(width: 96, height: 96)
                    .scaleEffect(bounce ? 1.15 : 0.8)
                    .opacity(bounce ? 0 : 0.8)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.proteinTeal)
                    .scaleEffect(bounce ? 1 : 0.5)
            }
            .padding(.top, 24)

            Text("Log Saved!")
                .font(AppTypography.largeTitle.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Your meal has been added to today's tracker. Keep up the momentum!")
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    private var summaryCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.coachOrange.opacity(0.25), AppTheme.warmSun.opacity(0.35)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay {
                            Image(systemName: "fork.knife")
                                .foregroundStyle(AppTheme.coachOrange)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mealName)
                            .font(AppTypography.headline)
                        Text(mealType.label)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                }

                Divider()

                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        LabelCapsText(text: "Protein", color: AppTheme.textSecondary)
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(protein)")
                                .font(.system(size: 36, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.proteinTeal)
                            Text("g")
                                .font(AppTypography.headline)
                                .foregroundStyle(AppTheme.proteinTeal)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        LabelCapsText(text: "Calories", color: AppTheme.textSecondary)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(calories)")
                                .font(AppTypography.title2.weight(.bold))
                            Text("kcal")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: onViewToday) {
                HStack(spacing: 8) {
                    Text("View in Today's Tracker")
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            Button(action: onLogAnother) {
                Label("Log Another Item", systemImage: "plus.circle")
            }
            .buttonStyle(OutlineButtonStyle())

            Button("Dismiss", action: onDismiss)
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.top, 4)
        }
    }
}

private struct KineticConfettiView: View {
    private let colors: [Color] = [
        AppTheme.coachOrange,
        AppTheme.proteinTeal,
        AppTheme.warmSun,
        AppTheme.inkBlack
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for index in 0..<36 {
                    let seed = Double(index)
                    let x = (sin(seed * 1.7 + t * 0.6) * 0.5 + 0.5) * size.width
                    let y = ((t * 90 + seed * 40).truncatingRemainder(dividingBy: Double(size.height + 80))) - 40
                    let rect = CGRect(x: x, y: y, width: 8, height: 8)
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: 2),
                        with: .color(colors[index % colors.count].opacity(0.85))
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    PostScanSuccessView(
        mealName: "Grilled Chicken Bowl",
        mealType: .lunch,
        protein: 35,
        calories: 420,
        onViewToday: {},
        onLogAnother: {},
        onDismiss: {}
    )
}
