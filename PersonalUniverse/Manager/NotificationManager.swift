//
//  NotificationManager.swift
//  PersonalUniverse
//

import Foundation
import Observation
import OSLog
import UserNotifications

// Injectable platform boundary: tests can simulate permission/add failures without changing device settings.
@MainActor
struct NotificationClient {
    var authorizationStatus: () async -> UNAuthorizationStatus
    var requestAuthorization: () async throws -> Bool
    var add: (UNNotificationRequest) async throws -> Void
    var remove: ([String]) -> Void
    var now: () -> Date = { .now }

    static let live = NotificationClient(
        authorizationStatus: { await UNUserNotificationCenter.current().notificationSettings().authorizationStatus },
        requestAuthorization: { try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) },
        add: { try await UNUserNotificationCenter.current().add($0) },
        remove: { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: $0) }
    )
}

@Observable
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private(set) var errorMessage: String?
    private(set) var permissionDenied = false
    private weak var lastChallenge: UniverseChallenge?

    @ObservationIgnored private var schedulingTask: Task<Void, Never>?
    @ObservationIgnored private var pendingChallenge: UniverseChallenge?
    private let client: NotificationClient

    init(client: NotificationClient? = nil) { self.client = client ?? .live }

    func retry() async {
        if let lastChallenge { await scheduleCurrentReminder(for: lastChallenge) }
        else if errorMessage != nil { _ = await requestPermission() }
    }

    private func report(_ message: String) {
        errorMessage = message
        Logger(subsystem: "PersonalUniverse", category: "Notifications").error("\(message, privacy: .public)")
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let status = await client.authorizationStatus()

            permissionDenied = false
            switch status {
            case .authorized, .provisional, .ephemeral:
                errorMessage = nil
                return true

            case .notDetermined:
                let granted = try await client.requestAuthorization()
                permissionDenied = !granted
                if granted { errorMessage = nil }
                else { report("Reminders are off in Settings. Your challenge is saved; enable notifications in Settings to receive reminders.") }
                return granted

            case .denied:
                permissionDenied = true
                report("Reminders are off in Settings. Your challenge is saved; enable notifications in Settings to receive reminders.")
                return false

            @unknown default:
                report("Notification availability could not be determined. Try again.")
                return false
            }
        } catch {
            report("Notification permission could not be checked. Your challenge is saved. Try again.")
            return false
        }
    }

    // MARK: - Schedule Current Reminder

    func scheduleCurrentReminder(for challenge: UniverseChallenge) async {
        // Serialize OS writes so a slower old request cannot replace a newer title/time.
        pendingChallenge = challenge
        if let schedulingTask { await schedulingTask.value; return }
        let task = Task { @MainActor in
            while let next = pendingChallenge {
                pendingChallenge = nil
                await performSchedule(for: next)
            }
            schedulingTask = nil
        }
        schedulingTask = task
        await task.value
    }

    private func performSchedule(for challenge: UniverseChallenge) async {
        lastChallenge = challenge
        // Challenge must still be active.
        guard challenge.status == .active else {
            cancelAllReminders(for: challenge)
            return
        }

        // Reminders must still be enabled.
        guard challenge.reminderEnabled else {
            cancelAllReminders(for: challenge)
            return
        }

        // Find the current day.
        guard let currentDay = challenge.currentDay else {
            cancelAllReminders(for: challenge)
            print("No current challenge day remains.")
            return
        }

        // A reminder is only valid for an upcoming day.
        guard currentDay.status == .upcoming else {
            errorMessage = nil
            print("Current challenge day is not upcoming.")
            cancelReminder(
                for: challenge,
                dayNumber: currentDay.dayNumber
            )
            return
        }

        let permitted = await requestPermission()
        guard isReminderCurrent(for: challenge, day: currentDay) else {
            cancelAllReminders(for: challenge)
            return
        }
        guard permitted else { return }

        let identifier = reminderIdentifier(
            for: challenge,
            dayNumber: currentDay.dayNumber
        )

        // Adding the same identifier replaces a request only on success.
        // Do not discard the previous reminder before a potentially failing add.

        let calendar = Calendar.current

        // Determine the actual calendar date
        // belonging to the current challenge day.
        guard let challengeDate = challenge.date(
            for: currentDay,
            calendar: calendar
        ) else {
            report("The reminder date could not be determined. Try again.")
            return
        }

        guard (0...23).contains(challenge.reminderHour), (0...59).contains(challenge.reminderMinute) else {
            report("The reminder time is invalid. Please check the challenge reminder settings.")
            return
        }
        var components = calendar.dateComponents(
            [.year, .month, .day],
            from: challengeDate
        )

        components.hour = challenge.reminderHour
        components.minute = challenge.reminderMinute
        components.second = 0

        guard let reminderDate = calendar.date(from: components) else {
            report("The reminder time is invalid. Please check the challenge reminder settings.")
            return
        }

        // Never schedule something in the past.
        guard reminderDate > client.now() else {
            cancelReminder(for: challenge, dayNumber: currentDay.dayNumber)
            errorMessage = nil
            print(
                "Reminder time has already passed for " +
                "Day \(currentDay.dayNumber)."
            )
            return
        }

        // MARK: Notification Content

        let content = UNMutableNotificationContent()
        content.title = challenge.title
        content.body = "Day \(currentDay.dayNumber) is waiting for you."
        content.sound = .default

        // MARK: Notification Trigger

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        // MARK: Notification Request

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        // MARK: Add Request

        do {
            try await client.add(request)
            guard isReminderCurrent(for: challenge, day: currentDay) else {
                cancelAllReminders(for: challenge)
                return
            }
            errorMessage = nil
            print(
                "Scheduled reminder for " +
                "Day \(currentDay.dayNumber) at " +
                "\(challenge.reminderHour):" +
                "\(String(format: "%02d", challenge.reminderMinute))"
            )
        } catch {
            // Completion/disable may happen while the OS is processing add().
            guard isReminderCurrent(for: challenge, day: currentDay) else {
                cancelAllReminders(for: challenge)
                return
            }
            report("Your challenge was saved, but its reminder could not be scheduled. Try again.")
        }
    }

    private func isReminderCurrent(for challenge: UniverseChallenge, day: ChallengeDay) -> Bool {
        challenge.status == .active && challenge.reminderEnabled && day.status == .upcoming &&
        challenge.currentDay?.dayNumber == day.dayNumber
    }

    // MARK: - Reschedule After Completion

    func rescheduleAfterCompletion(
        for challenge: UniverseChallenge,
        completedDayNumber: Int
    ) async {
        // Always remove the reminder belonging
        // to the day that was just completed.
        cancelReminder(
            for: challenge,
            dayNumber: completedDayNumber
        )

        // If the challenge itself is now completed,
        // absolutely no further notification should exist.
        guard challenge.status == .active else {
            cancelAllReminders(for: challenge)
            print(
                "Challenge completed. " +
                "All future reminders cancelled."
            )
            return
        }

        // If reminders are disabled, remove everything.
        guard challenge.reminderEnabled else {
            cancelAllReminders(for: challenge)
            return
        }

        // There must be another current day.
        guard let nextDay = challenge.currentDay else {
            cancelAllReminders(for: challenge)
            print(
                "No next day remains. " +
                "No further reminder scheduled."
            )
            return
        }

        // The next day must actually be upcoming.
        guard nextDay.status == .upcoming else {
            cancelAllReminders(for: challenge)
            print(
                "No upcoming day available. " +
                "No further reminder scheduled."
            )
            return
        }

        // Schedule ONLY the next current day.
        await scheduleCurrentReminder(for: challenge)
    }

    // MARK: - Cancel Reminder

    func cancelReminder(
        for challenge: UniverseChallenge,
        dayNumber: Int
    ) {
        let identifier = reminderIdentifier(
            for: challenge,
            dayNumber: dayNumber
        )

        client.remove([identifier])

        print("Cancelled reminder for Day \(dayNumber)")
    }

    // MARK: - Cancel All Challenge Reminders

    func cancelAllReminders(for challenge: UniverseChallenge) {
        if lastChallenge == nil || lastChallenge?.id == challenge.id {
            errorMessage = nil
            permissionDenied = false
            lastChallenge = nil
        }
        let identifiers = challenge.orderedDays.map {
            reminderIdentifier(
                for: challenge,
                dayNumber: $0.dayNumber
            )
        }

        client.remove(identifiers)

        print("Cancelled all reminders for \(challenge.title)")
    }

    // MARK: - Identifier

    private func reminderIdentifier(
        for challenge: UniverseChallenge,
        dayNumber: Int
    ) -> String {
        "PersonalUniverse." +
        "\(challenge.id.uuidString)." +
        "day.\(dayNumber)"
    }
}
