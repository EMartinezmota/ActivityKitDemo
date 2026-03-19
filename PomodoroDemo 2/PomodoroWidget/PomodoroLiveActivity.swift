import ActivityKit
import SwiftUI
import WidgetKit

struct PomodoroLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroAttributes.self) { context in
            // LOCK SCREEN / NOTIFICATION BANNER
            lockScreenView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                // EXPANDED Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: context.state.phase.systemImage)
                            .foregroundStyle(phaseColor(context.state.phase))
                        Text(context.state.phase.rawValue)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.timeFormatted)
                        .font(.title2.monospacedDigit().bold())
                        .foregroundStyle(phaseColor(context.state.phase))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        ProgressView(value: context.state.progress)
                            .tint(phaseColor(context.state.phase))

                        HStack {
                            sessionDots(state: context.state)
                            Spacer()
                            HStack(spacing: 4) {
                                Text(context.state.moonEmoji)
                                    .font(.caption)
                                Text(context.state.moonPhaseName)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                    }
                }
            } compactLeading: {
                // COMPACT leading (left of Dynamic Island pill)
                Image(systemName: context.state.phase.systemImage)
                    .foregroundStyle(phaseColor(context.state.phase))
                    .font(.caption)
            } compactTrailing: {
                // COMPACT trailing (right of Dynamic Island pill)
                Text(context.state.timeFormatted)
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(phaseColor(context.state.phase))
            } minimal: {
                // MINIMAL (when another Live Activity takes priority)
                Image(systemName: context.state.phase.systemImage)
                    .foregroundStyle(phaseColor(context.state.phase))
                    .font(.caption)
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    func lockScreenView(state: PomodoroAttributes.ContentState) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: state.phase.systemImage)
                    .foregroundStyle(phaseColor(state.phase))
                Text(state.phase.rawValue)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Spacer()
                Text(state.timeFormatted)
                    .font(.title2.monospacedDigit().bold())
                    .foregroundStyle(.white)
            }

            ProgressView(value: state.progress)
                .tint(phaseColor(state.phase))

            HStack {
                sessionDots(state: state)
                Spacer()
                HStack(spacing: 4) {
                    Text(state.moonEmoji)
                        .font(.caption)
                    Text(state.moonPhaseName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.85))
    }

    // MARK: - Helpers

    func phaseColor(_ phase: PomodoroAttributes.ContentState.Phase) -> Color {
        switch phase {
        case .focus: return .red
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }

    func sessionDots(state: PomodoroAttributes.ContentState) -> some View {
        HStack(spacing: 6) {
            ForEach(1...state.totalSessions, id: \.self) { i in
                if i <= state.completedSessions {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.caption)
                }
            }
        }
    }
}
