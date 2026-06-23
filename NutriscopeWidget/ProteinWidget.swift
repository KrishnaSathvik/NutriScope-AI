import SwiftUI
import WidgetKit

struct ProteinWidgetEntry: TimelineEntry {
    let date: Date
    let proteinCurrent: Int
    let proteinTarget: Int
    let proteinRemaining: Int
    let sleepHours: Double
    let workoutMinutes: Int
    let coachTip: String
}

struct ProteinWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ProteinWidgetEntry {
        ProteinWidgetEntry(
            date: .now,
            proteinCurrent: 72,
            proteinTarget: 135,
            proteinRemaining: 63,
            sleepHours: 7.2,
            workoutMinutes: 45,
            coachTip: "63g protein left today."
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ProteinWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProteinWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> ProteinWidgetEntry {
        let store = UserDefaults(suiteName: "group.com.nutriscopeai.app") ?? .standard
        return ProteinWidgetEntry(
            date: .now,
            proteinCurrent: store.integer(forKey: "widget.proteinCurrent"),
            proteinTarget: max(store.integer(forKey: "widget.proteinTarget"), 1),
            proteinRemaining: store.integer(forKey: "widget.proteinRemaining"),
            sleepHours: store.double(forKey: "widget.sleepHours"),
            workoutMinutes: store.integer(forKey: "widget.workoutMinutes"),
            coachTip: store.string(forKey: "widget.coachTip") ?? "Log a meal to track protein."
        )
    }
}

struct ProteinWidgetView: View {
    let entry: ProteinWidgetEntry

    private var progress: Double {
        guard entry.proteinTarget > 0 else { return 0 }
        return min(Double(entry.proteinCurrent) / Double(entry.proteinTarget), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Nutriscope")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(red: 0.66, green: 0.22, blue: 0.01))
                Spacer()
                Text("\(entry.proteinRemaining)g left")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(entry.proteinCurrent)")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 0.95, green: 0.42, blue: 0.22))
                Text("/ \(entry.proteinTarget)g")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .tint(Color(red: 0.95, green: 0.42, blue: 0.22))

            HStack(spacing: 12) {
                if entry.sleepHours > 0 {
                    Label(String(format: "%.1fh sleep", entry.sleepHours), systemImage: "bed.double.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if entry.workoutMinutes > 0 {
                    Label("\(entry.workoutMinutes)m workout", systemImage: "figure.run")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(entry.coachTip)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(red: 0.98, green: 0.98, blue: 0.96)
        }
    }
}

struct ProteinWidget: Widget {
    let kind = "ProteinWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProteinWidgetProvider()) { entry in
            ProteinWidgetView(entry: entry)
        }
        .configurationDisplayName("Protein Progress")
        .description("Daily protein, sleep, and workout at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct NutriscopeWidgetBundle: WidgetBundle {
    var body: some Widget {
        ProteinWidget()
    }
}
