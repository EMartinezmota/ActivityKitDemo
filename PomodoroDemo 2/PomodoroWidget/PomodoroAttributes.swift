import ActivityKit
import Foundation

struct PomodoroAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phase: Phase
        var secondsRemaining: Int
        var totalSeconds: Int
        var completedSessions: Int
        var totalSessions: Int
        var moonPhaseName: String
        var moonEmoji: String

        enum Phase: String, Codable, Hashable {
            case focus = "Focus"
            case shortBreak = "Short Break"
            case longBreak = "Long Break"

            var systemImage: String {
                switch self {
                case .focus: return "brain.head.profile"
                case .shortBreak: return "cup.and.saucer"
                case .longBreak: return "bed.double"
                }
            }

            var durationSeconds: Int {
                switch self {
                case .focus: return 25 * 60
                case .shortBreak: return 5 * 60
                case .longBreak: return 15 * 60
                }
            }
        }

        var progress: Double {
            guard totalSeconds > 0 else { return 0 }
            return 1.0 - Double(secondsRemaining) / Double(totalSeconds)
        }

        var timeFormatted: String {
            String(format: "%02d:%02d", secondsRemaining / 60, secondsRemaining % 60)
        }
    }
}
