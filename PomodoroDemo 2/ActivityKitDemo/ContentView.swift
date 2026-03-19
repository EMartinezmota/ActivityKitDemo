import SwiftUI
import ActivityKit

struct ContentView: View {
    @StateObject private var manager = PomodoroActivityManager()

    @State private var phase: PomodoroAttributes.ContentState.Phase = .focus
    @State private var secondsRemaining: Int = PomodoroAttributes.ContentState.Phase.focus.durationSeconds
    @State private var completedSessions = 0
    @State private var totalSessions = 4
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var activitiesSupported = false
    @State private var moonPhaseName = "Loading..."
    @State private var moonEmoji = "🌙"

    var totalSeconds: Int { phase.durationSeconds }

    var currentState: PomodoroAttributes.ContentState {
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

    var phaseColor: Color {
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
                activitiesSupported = ActivityAuthorizationInfo().areActivitiesEnabled
                fetchMoonPhase { info in
                    DispatchQueue.main.async {
                        moonPhaseName = info.name
                        moonEmoji = info.emoji
                    }
                }
            }
        }
    }

    var supportBanner: some View {
        HStack {
            Image(systemName: activitiesSupported ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(activitiesSupported ? .green : .orange)
            Text(activitiesSupported ? "Live Activities enabled" : "Live Activities unavailable on simulator — preview shown below")
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(activitiesSupported ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    var timerCard: some View {
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

    var sessionDots: some View {
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

    var progressBar: some View {
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

    var phaseControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Manual Controls")
                .font(.headline)

            Text("Manually advance the phase or scrub time to show different states in the Live Activity preview.")
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

    func phaseButton(_ p: PomodoroAttributes.ContentState.Phase) -> some View {
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

    var activityControls: some View {
        VStack(spacing: 10) {
            if !manager.isActivityRunning {
                Button("Start Live Activity") {
                    manager.start(state: currentState)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            } else {
                Button("Stop Live Activity", role: .destructive) {
                    manager.stop()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
    }

    var conceptCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How this uses ActivityKit")
                .font(.headline)

            row(icon: "doc.text", color: .purple, title: "PomodoroAttributes",
                body: "ContentState holds phase, time, session progress, and live moon phase data — everything that changes. The moon phase is fetched once on launch and stored in state.")

            row(icon: "arrow.triangle.2.circlepath", color: .orange, title: "Continuous updates",
                body: "Every second the timer fires, activity.update() pushes a new ContentState to the Lock Screen and Dynamic Island.")

            row(icon: "moon.stars", color: .indigo, title: "US Navy Moon API",
                body: "Fetches the 4 nearest primary moon phases (new, first quarter, full, last quarter) from aa.usno.navy.mil — no API key required. Falls back to arithmetic calculation if offline.")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    func row(icon: String, color: Color, title: String, body: String) -> some View {
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

    func startTimer() {
        isRunning = true
        if !manager.isActivityRunning {
            manager.start(state: currentState)
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if secondsRemaining > 0 {
                secondsRemaining -= 1
                manager.update(state: currentState)
            } else {
                advanceSession()
            }
        }
    }

    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func switchPhase(to newPhase: PomodoroAttributes.ContentState.Phase) {
        pauseTimer()
        phase = newPhase
        secondsRemaining = newPhase.durationSeconds
        syncActivity()
    }

    func advanceSession() {
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

    func syncActivity() {
        guard manager.isActivityRunning else { return }
        manager.update(state: currentState)
    }
}

#Preview {
    ContentView()
}
