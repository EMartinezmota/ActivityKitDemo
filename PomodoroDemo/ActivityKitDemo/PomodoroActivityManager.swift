import ActivityKit
import Foundation

/// Handles the lifecycle of the Pomodoro Live Activity for real devices.
///
/// This manager owns a single `Activity<PomodoroAttributes>` instance and exposes simple
/// start/update/stop methods that the UI can call.
@MainActor
final class PomodoroActivityManager: ObservableObject {
    @Published private(set) var isActivityRunning = false

    private var activity: Activity<PomodoroAttributes>?

    init() {
        // If the app is relaunched while a Live Activity is still active, attach to it so
        // the UI can continue to update/stop it instead of creating duplicates.
        restoreExistingActivityIfNeeded()
    }

    /// Returns whether Live Activities are currently enabled for this device + app.
    var canStartActivities: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// Starts a new Live Activity if one is not already running.
    func start(state: PomodoroAttributes.ContentState) {
        guard canStartActivities else {
            print("Live Activities are disabled on this device or for this app.")
            return
        }

        guard activity == nil else {
            // Already running; just keep it in sync.
            update(state: state)
            return
        }

        let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(90))

        do {
            activity = try Activity.request(
                attributes: PomodoroAttributes(),
                content: content,
                pushType: nil
            )
            isActivityRunning = true
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    /// Pushes a new state to the current Live Activity.
    func update(state: PomodoroAttributes.ContentState) {
        guard let activity else { return }

        Task {
            await activity.update(ActivityContent(state: state, staleDate: Date().addingTimeInterval(90)))
        }
    }

    /// Ends the current Live Activity immediately.
    func stop(finalState: PomodoroAttributes.ContentState? = nil) {
        guard let activity else { return }

        Task {
            if let finalState {
                await activity.end(
                    ActivityContent(state: finalState, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            } else {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }

        isActivityRunning = false
        self.activity = nil
    }

    /// Attempts to attach to an existing activity from a previous app launch.
    private func restoreExistingActivityIfNeeded() {
        guard activity == nil else { return }

        activity = Activity<PomodoroAttributes>.activities.first
        isActivityRunning = activity != nil
    }
}
