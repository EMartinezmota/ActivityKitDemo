import SwiftUI

struct LiveActivityPreviewView: View {
    let state: PomodoroAttributes.ContentState

    var phaseColor: Color {
        switch state.phase {
        case .focus: return .red
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Live Activity Preview")
                .font(.caption)
                .foregroundStyle(.secondary)

            lockScreenBanner
            dynamicIslandRow
        }
    }

    var lockScreenBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Lock Screen")
                .font(.caption2)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                HStack {
                    Image(systemName: state.phase.systemImage)
                        .foregroundStyle(phaseColor)
                    Text(state.phase.rawValue)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Text(state.timeFormatted)
                        .font(.title2.monospacedDigit().bold())
                        .foregroundStyle(.white)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.2))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(phaseColor)
                            .frame(width: geo.size.width * state.progress, height: 6)
                            .animation(.linear(duration: 0.5), value: state.progress)
                    }
                }
                .frame(height: 6)

                HStack {
                    sessionDots
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
            .background(.black.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    var sessionDots: some View {
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

    var dynamicIslandRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Dynamic Island (compact)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: state.phase.systemImage)
                        .foregroundStyle(phaseColor)
                        .font(.caption)
                    Text(state.timeFormatted)
                        .font(.caption.monospacedDigit().bold())
                        .foregroundStyle(.white)
                    Text("·")
                        .foregroundStyle(.white.opacity(0.4))
                    Text(state.moonEmoji)
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.black)
                .clipShape(Capsule())
                Spacer()
            }
        }
    }
}
