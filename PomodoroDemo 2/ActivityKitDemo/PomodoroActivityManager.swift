import ActivityKit
import Foundation

class PomodoroActivityManager: ObservableObject {
    @Published var isActivityRunning = false
    private var activity: Activity<PomodoroAttributes>?

    func start(state: PomodoroAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let content = ActivityContent(state: state, staleDate: nil)
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

    func update(state: PomodoroAttributes.ContentState) {
        guard let activity else { return }
        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    func stop() {
        guard let activity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        isActivityRunning = false
        self.activity = nil
    }
}
