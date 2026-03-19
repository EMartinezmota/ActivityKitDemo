import SwiftUI
import ActivityKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var manager = PomodoroActivityManager()

    @State private var phase: PomodoroAttributes.ContentState.Phase = .focus
    @State private var secondsRemaining: Int = PomodoroAttributes.ContentState.Phase.focus.durationSeconds
    @State private var completedSessions = 0
    @State private var totalSessions = 4
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var moonPhaseName = "Loading..."
    @State private var moonEmoji = "🌙"

    private var totalSeconds: Int { phase.durationSeconds }

    /// The exact state we send to ActivityKit and render in the in-app preview.
    private var currentState: PomodoroAttributes.ContentState {
        PomodoroAttributes.ContentState(
            phase: phase,
            secondsRemaining: secondsRemaining,
            totalSeconds: totalSeconds,
            completedSessions: completedSessions,
            totalSessions: totalSessions,
            moonPhaseName: moonPhaseName,
            moonEmoji: moonEmoji
        )
    }

    private var phaseColor: Color {
        switch phase {
        case .focus: return .red
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    supportBanner
                    timerCard
                    phaseControls
                    if manager.isActivityRunning {
                        LiveActivityPreviewView(state: currentState)
                    }
                    activityControls
                    conceptCard
                }
                .padding()
            }
            .navigationTitle("Pomodoro Demo")
            .onAppear {
                fetchMoonPhase { info in
                    DispatchQueue.main.async {
                        moonPhaseName = info.name
                        moonEmoji = info.emoji
                    }
                }
            }
            .onDisappear {
                pauseTimer()
            }
            .onChange(of: scenePhase) { _, newValue in
                // Timers are not reliable in background. We pause and keep the latest state synced.
                if newValue != .active {
                    pauseTimer()
                    syncActivity()
                }
            }
        }
    }

    private var supportBanner: some View {
        HStack {
            Image(systemName: manager.canStartActivities ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(manager.canStartActivities ? .green : .orange)
            Text(manager.canStartActivities ? "Live Activities enabled" : "Live Activities unavailable on this device/settings")
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(manager.canStartActivities ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var timerCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: phase.systemImage)
                    .foregroundStyle(phaseColor)
                Text(phase.rawValue)
                    .font(.headline)
                Spacer()
                sessionDots
            }

            Text(currentState.timeFormatted)
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .foregroundStyle(phaseColor)

            progressBar

            HStack(spacing: 4) {
                Text(moonEmoji)
                Text(moonPhaseName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(isRunning ? "Pause" : "Start") {
                isRunning ? pauseTimer() : startTimer()
            }
            .buttonStyle(.borderedProminent)
            .tint(phaseColor)
            .controlSize(.large)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var sessionDots: some View {
        HStack(spacing: 6) {
            ForEach(1...totalSessions, id: \.self) { i in
                if i <= completedSessions {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(height: 10)
                RoundedRectangle(cornerRadius: 6)
                    .fill(phaseColor)
                    .frame(width: geo.size.width * currentState.progress, height: 10)
                    .animation(.linear(duration: 0.5), value: currentState.progress)
            }
        }
        .frame(height: 10)
    }

    private var phaseControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Manual Controls")
                .font(.headline)

            Text("Manually advance phase or scrub time to test realistic Live Activity states.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                phaseButton(.focus)
                phaseButton(.shortBreak)
                phaseButton(.longBreak)
            }

            HStack(spacing: 10) {
                Button {
                    secondsRemaining = max(0, secondsRemaining - 60)
                    syncActivity()
                } label: {
                    Label("−1 min", systemImage: "backward.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(secondsRemaining < 60)

                Button {
                    secondsRemaining = max(0, secondsRemaining - 300)
                    syncActivity()
                } label: {
                    Label("−5 min", systemImage: "backward.end.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(secondsRemaining < 300)
            }

            HStack(spacing: 10) {
                Button {
                    advanceSession()
                } label: {
                    Label("Skip to Next Phase", systemImage: "forward.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    if completedSessions < totalSessions {
                        completedSessions += 1
                        syncActivity()
                    }
                } label: {
                    Label("Complete Session", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(completedSessions >= totalSessions)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func phaseButton(_ p: PomodoroAttributes.ContentState.Phase) -> some View {
        let selected = phase == p
        return Button {
            switchPhase(to: p)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: p.systemImage)
                Text(p.rawValue)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
        .tint(selected ? phaseColor : .secondary)
        .background(selected ? phaseColor.opacity(0.1) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
    }

    private var activityControls: some View {
        VStack(spacing: 10) {
            if !manager.isActivityRunning {
                Button("Start Live Activity") {
                    manager.start(state: currentState)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!manager.canStartActivities)
            } else {
                Button("Stop Live Activity", role: .destructive) {
                    manager.stop(finalState: currentState)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var conceptCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How this uses ActivityKit")
                .font(.headline)

            row(icon: "doc.text", color: .purple, title: "PomodoroAttributes",
                body: "ContentState holds phase, remaining time, session progress, and moon phase metadata.")

            row(icon: "arrow.triangle.2.circlepath", color: .orange, title: "Live updates",
                body: "Every tick updates state in-app and pushes the same state to ActivityKit so Lock Screen/Dynamic Island stay in sync.")

            row(icon: "moon.stars", color: .indigo, title: "Moon phase source",
                body: "Reads nearest primary phases from US Navy API (no key). Falls back to local calculation when offline.")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func row(icon: String, color: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(color, in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.bold())
                Text(body).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// Starts the one-second timer and creates a Live Activity if needed.
    private func startTimer() {
        isRunning = true

        if !manager.isActivityRunning {
            manager.start(state: currentState)
        }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if secondsRemaining > 0 {
                secondsRemaining -= 1
                manager.update(state: currentState)
            } else {
                advanceSession()
            }
        }
    }

    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func switchPhase(to newPhase: PomodoroAttributes.ContentState.Phase) {
        pauseTimer()
        phase = newPhase
        secondsRemaining = newPhase.durationSeconds
        syncActivity()
    }

    private func advanceSession() {
        pauseTimer()

        switch phase {
        case .focus:
            completedSessions = min(completedSessions + 1, totalSessions)
            syncActivity()
            if completedSessions % 4 == 0 {
                switchPhase(to: .longBreak)
            } else {
                switchPhase(to: .shortBreak)
            }
        case .shortBreak, .longBreak:
            switchPhase(to: .focus)
        }
    }

    private func syncActivity() {
        guard manager.isActivityRunning else { return }
        manager.update(state: currentState)
    }
}

#Preview {
    ContentView()
}
