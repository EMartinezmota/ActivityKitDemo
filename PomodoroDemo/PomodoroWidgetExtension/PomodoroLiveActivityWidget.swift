import ActivityKit
import SwiftUI
import WidgetKit

/// Real Live Activity UI rendered by iOS on the Lock Screen and Dynamic Island.
struct PomodoroLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroAttributes.self) { context in
            let state = context.state

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(state.phase.rawValue, systemImage: state.phase.systemImage)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(state.timeFormatted)
                        .font(.title2.monospacedDigit().bold())
                }

                ProgressView(value: state.progress)
                    .progressViewStyle(.linear)
                    .tint(phaseColor(for: state.phase))

                HStack(spacing: 6) {
                    Text("\(state.completedSessions)/\(state.totalSessions) sessions")
                    Spacer()
                    Text("\(state.moonEmoji) \(state.moonPhaseName)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
            .activityBackgroundTint(Color(.systemBackground))
            .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            let state = context.state

            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(state.phase.rawValue, systemImage: state.phase.systemImage)
                        .font(.subheadline)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(state.timeFormatted)
                        .font(.title3.monospacedDigit().bold())
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        ProgressView(value: state.progress)
                            .progressViewStyle(.linear)
                            .tint(phaseColor(for: state.phase))
                        Text(state.moonEmoji)
                    }
                }
            } compactLeading: {
                Image(systemName: state.phase.systemImage)
            } compactTrailing: {
                Text(state.timeFormatted)
                    .font(.caption2.monospacedDigit())
            } minimal: {
                Text(state.moonEmoji)
            }
        }
    }

    private func phaseColor(for phase: PomodoroAttributes.ContentState.Phase) -> Color {
        switch phase {
        case .focus: return .red
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }
}
