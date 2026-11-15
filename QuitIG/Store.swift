import Foundation
import SwiftUI

enum DayStatus: String, Codable {
    case ok, bad
}

enum DayKey {
    static let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = .current
        c.firstWeekday = 1
        return c
    }()
    static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.calendar = cal
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    static let thai: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "th_TH")
        f.calendar = Calendar(identifier: .buddhist)
        f.dateFormat = "EEEEที่ d MMMM"
        return f
    }()
    static let thaiMonth: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "th_TH")
        f.calendar = Calendar(identifier: .buddhist)
        f.dateFormat = "MMMM yyyy"
        return f
    }()
    static func key(_ d: Date) -> String { fmt.string(from: d) }
    static func today() -> Date { cal.startOfDay(for: Date()) }
    static func add(_ d: Date, _ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: d) ?? d }
    static func thaiDate(_ d: Date) -> String { thai.string(from: d) }
    static let shortDays = ["อา", "จ", "อ", "พ", "พฤ", "ศ", "ส"]
}

@MainActor
final class Store: ObservableObject {
    @Published var log: [String: DayStatus] = [:] { didSet { save() } }
    @Published var reason: String = "" { didSet { save() } }
    @Published var urges: Int = 0 { didSet { save() } }
    @Published var alarmEnabled: Bool = false { didSet { save() } }
    @Published var alarmHour: Int = 19 { didSet { save() } }
    @Published var alarmMinute: Int = 30 { didSet { save() } }
    @Published var alarmID: String? = nil { didSet { save() } }

    private struct Saved: Codable {
        var log: [String: DayStatus]
        var reason: String
        var urges: Int
        var alarmEnabled: Bool
        var alarmHour: Int
        var alarmMinute: Int
        var alarmID: String?
    }

    private let storeKey = "quit-ig-state-v1"
    private var loading = false

    init() { load() }

    private func load() {
        loading = true
        defer { loading = false }
        guard let data = UserDefaults.standard.data(forKey: storeKey),
              let s = try? JSONDecoder().decode(Saved.self, from: data) else { return }
        log = s.log
        reason = s.reason
        urges = s.urges
        alarmEnabled = s.alarmEnabled
        alarmHour = s.alarmHour
        alarmMinute = s.alarmMinute
        alarmID = s.alarmID
    }

    private func save() {
        if loading { return }
        let s = Saved(log: log, reason: reason, urges: urges, alarmEnabled: alarmEnabled,
                      alarmHour: alarmHour, alarmMinute: alarmMinute, alarmID: alarmID)
        if let data = try? JSONEncoder().encode(s) {
            UserDefaults.standard.set(data, forKey: storeKey)
        }
    }

    // MARK: - Stats

    func status(_ d: Date) -> DayStatus? { log[DayKey.key(d)] }

    func set(_ d: Date, _ s: DayStatus?) {
        let k = DayKey.key(d)
        if let s { log[k] = s } else { log.removeValue(forKey: k) }
    }

    var streak: Int {
        let t = DayKey.today()
        if status(t) == .bad { return 0 }
        var d = status(t) == .ok ? t : DayKey.add(t, -1)
        var n = 0
        while status(d) == .ok { n += 1; d = DayKey.add(d, -1) }
        return n
    }

    var best: Int {
        var b = 0, cur = 0
        var prev: String? = nil
        for k in log.keys.sorted() {
            if log[k] == .ok {
                if let p = prev, let pd = DayKey.fmt.date(from: p), DayKey.key(DayKey.add(pd, 1)) == k {
                    cur += 1
                } else { cur = 1 }
                prev = k
                b = max(b, cur)
            } else { cur = 0; prev = nil }
        }
        return b
    }

    var totalOK: Int { log.values.filter { $0 == .ok }.count }

    static let milestones = [1, 3, 7, 14, 21, 30, 60, 90, 180, 365]
    func nextGoal(_ s: Int) -> Int { Store.milestones.first { $0 > s } ?? (s + 100) }
    func prevGoal(_ s: Int) -> Int { Store.milestones.last { $0 <= s } ?? 0 }
}
