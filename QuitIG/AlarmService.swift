import Foundation
import SwiftUI
import AlarmKit
import AppIntents
import UserNotifications

struct CheckInMetadata: AlarmMetadata {}

/// Button on the alarm screen that opens the app to check in.
struct OpenCheckInIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "เปิดเช็คอิน"
    static var openAppWhenRun: Bool = true
    init() {}
    func perform() async throws -> some IntentResult { .result() }
}

enum AlarmMode {
    case alarm          // AlarmKit: full alarm, rings on lock screen and in silent mode
    case notification   // fallback: normal notification with sound
}

enum AlarmServiceError: Error {
    case notAllowed
}

@MainActor
enum AlarmService {
    static let notifID = "quit-ig-daily"

    /// Schedules a daily alarm. Returns the alarm id (AlarmKit) and which mode was used.
    static func schedule(hour: Int, minute: Int, replacing oldID: String?) async throws -> (String?, AlarmMode) {
        await cancel(oldID)
        do {
            let id = try await scheduleAlarmKit(hour: hour, minute: minute)
            return (id, .alarm)
        } catch {
            try await scheduleNotification(hour: hour, minute: minute)
            return (nil, .notification)
        }
    }

    static func cancel(_ oldID: String?) async {
        if let oldID, let uuid = UUID(uuidString: oldID) {
            try? AlarmManager.shared.cancel(id: uuid)
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notifID])
    }

    private static func scheduleAlarmKit(hour: Int, minute: Int) async throws -> String {
        let manager = AlarmManager.shared
        var state = manager.authorizationState
        if state == .notDetermined {
            state = try await manager.requestAuthorization()
        }
        guard state == .authorized else { throw AlarmServiceError.notAllowed }

        let stop = AlarmButton(text: "ปิด", textColor: .white, systemImageName: "xmark")
        let open = AlarmButton(text: "เช็คอิน", textColor: .white, systemImageName: "checkmark.circle.fill")
        let alert = AlarmPresentation.Alert(
            title: "วันนี้เลิก IG ได้ไหม?",
            stopButton: stop,
            secondaryButton: open,
            secondaryButtonBehavior: .custom
        )
        let attributes = AlarmAttributes<CheckInMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: CheckInMetadata(),
            tintColor: Color(red: 0.12, green: 0.62, blue: 0.42)
        )
        let days: [Locale.Weekday] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        let time = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
        let schedule = Alarm.Schedule.relative(.init(time: time, repeats: .weekly(days)))
        let config = AlarmManager.AlarmConfiguration<CheckInMetadata>(
            schedule: schedule,
            attributes: attributes,
            secondaryIntent: OpenCheckInIntent()
        )
        let id = UUID()
        _ = try await manager.schedule(id: id, configuration: config)
        return id.uuidString
    }

    private static func scheduleNotification(hour: Int, minute: Int) async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard granted else { throw AlarmServiceError.notAllowed }
        let content = UNMutableNotificationContent()
        content.title = "⏰ ถึงเวลาเช็คอินแล้ว"
        content.body = "วันนี้เลิก IG ได้ไหม? เข้ามากดบันทึกเลย"
        content.sound = .default
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        try await center.add(UNNotificationRequest(identifier: notifID, content: content, trigger: trigger))
    }
}
