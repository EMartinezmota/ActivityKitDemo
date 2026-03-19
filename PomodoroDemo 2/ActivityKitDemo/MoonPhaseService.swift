import Foundation

struct MoonPhaseInfo {
    let name: String
    let emoji: String
}

func fetchMoonPhase(completion: @escaping (MoonPhaseInfo) -> Void) {
    let today = Date()
    let calendar = Calendar.current
    let year = calendar.component(.year, from: today)
    let month = calendar.component(.month, from: today)
    let day = calendar.component(.day, from: today)

    let urlString = "https://aa.usno.navy.mil/api/moon/phases/date?date=\(year)-\(month)-\(day)&nump=4"
    guard let url = URL(string: urlString) else {
        completion(fallbackMoonPhase())
        return
    }

    URLSession.shared.dataTask(with: url) { data, _, error in
        guard let data, error == nil,
              let decoded = try? JSONDecoder().decode(USNavyMoonResponse.self, from: data) else {
            completion(fallbackMoonPhase())
            return
        }

        let currentPhase = closestPhase(from: decoded.phasedata, to: today)
        completion(currentPhase)
    }.resume()
}

private struct USNavyMoonResponse: Codable {
    let phasedata: [PhaseEntry]
}

private struct PhaseEntry: Codable {
    let phase: String
    let date: String
    let time: String
}

private func closestPhase(from entries: [PhaseEntry], to date: Date) -> MoonPhaseInfo {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy MMM dd HH:mm"
    formatter.locale = Locale(identifier: "en_US")

    var closest: (distance: TimeInterval, name: String) = (.greatestFiniteMagnitude, "New Moon")

    for entry in entries {
        let dateString = "\(entry.date) \(entry.time)"
        if let phaseDate = formatter.date(from: dateString) {
            let distance = abs(phaseDate.timeIntervalSince(date))
            if distance < closest.distance {
                closest = (distance, entry.phase)
            }
        }
    }

    return moonInfo(for: closest.name)
}

private func moonInfo(for phaseName: String) -> MoonPhaseInfo {
    switch phaseName.lowercased() {
    case let s where s.contains("new"):
        return MoonPhaseInfo(name: "New Moon", emoji: "🌑")
    case let s where s.contains("first"):
        return MoonPhaseInfo(name: "First Quarter", emoji: "🌓")
    case let s where s.contains("full"):
        return MoonPhaseInfo(name: "Full Moon", emoji: "🌕")
    case let s where s.contains("last") || s.contains("third"):
        return MoonPhaseInfo(name: "Last Quarter", emoji: "🌗")
    default:
        return fallbackMoonPhase()
    }
}

private func fallbackMoonPhase() -> MoonPhaseInfo {
    let age = moonAgeFromEpoch()
    switch age {
    case 0..<1.85:   return MoonPhaseInfo(name: "New Moon", emoji: "🌑")
    case 1.85..<5.5: return MoonPhaseInfo(name: "Waxing Crescent", emoji: "🌒")
    case 5.5..<9.2:  return MoonPhaseInfo(name: "First Quarter", emoji: "🌓")
    case 9.2..<12.9: return MoonPhaseInfo(name: "Waxing Gibbous", emoji: "🌔")
    case 12.9..<16.6:return MoonPhaseInfo(name: "Full Moon", emoji: "🌕")
    case 16.6..<20.3:return MoonPhaseInfo(name: "Waning Gibbous", emoji: "🌖")
    case 20.3..<24.0:return MoonPhaseInfo(name: "Last Quarter", emoji: "🌗")
    case 24.0..<27.7:return MoonPhaseInfo(name: "Waning Crescent", emoji: "🌘")
    default:          return MoonPhaseInfo(name: "New Moon", emoji: "🌑")
    }
}

private func moonAgeFromEpoch() -> Double {
    let knownNewMoon = Date(timeIntervalSince1970: 592488000)
    let lunarCycle = 29.53058867
    let elapsed = Date().timeIntervalSince(knownNewMoon)
    let cycles = elapsed / (lunarCycle * 86400)
    return (cycles - floor(cycles)) * lunarCycle
}
