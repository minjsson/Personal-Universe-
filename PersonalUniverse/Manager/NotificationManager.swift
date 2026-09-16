//
//  NotificationManager.swift
//  PersonalUniverse
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let settings = await center.notificationSettings()

            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                return true

            case .notDetermined:
                return try await center.requestAuthorization(
                    options: [.alert, .sound]
                )

            case .denied:
                print("Notification permission has been denied.")
                return false

            @unknown default:
                return false
            }
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    // MARK: - Schedule Current Reminder

    func scheduleCurrentReminder(for challenge: UniverseChallenge) async {
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
            print("Current challenge day is not upcoming.")
            cancelReminder(
                for: challenge,
                dayNumber: currentDay.dayNumber
            )
            return
        }

        let identifier = reminderIdentifier(
            for: challenge,
            dayNumber: currentDay.dayNumber
        )

        let center = UNUserNotificationCenter.current()

        // Remove an existing reminder for this day
        // before creating a new one.
        center.removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )

        let calendar = Calendar.current

        // Determine the actual calendar date
        // belonging to the current challenge day.
        guard let challengeDate = challenge.date(
            for: currentDay,
            calendar: calendar
        ) else {
            print("Could not determine date for Day \(currentDay.dayNumber).")
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
            print("Could not create reminder date.")
            return
        }

        // Never schedule something in the past.
        guard reminderDate > .now else {
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
            try await center.add(request)
            print(
                "Scheduled reminder for " +
                "Day \(currentDay.dayNumber) at " +
                "\(challenge.reminderHour):" +
                "\(String(format: "%02d", challenge.reminderMinute))"
            )
        } catch {
            print("Failed to schedule reminder: \(error)")
        }
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

        UNUserNotificationCenter
            .current()
            .removePendingNotificationRequests(
                withIdentifiers: [identifier]
            )

        print("Cancelled reminder for Day \(dayNumber)")
    }

    // MARK: - Cancel All Challenge Reminders

    func cancelAllReminders(for challenge: UniverseChallenge) {
        let identifiers = challenge.orderedDays.map {
            reminderIdentifier(
                for: challenge,
                dayNumber: $0.dayNumber
            )
        }

        UNUserNotificationCenter
            .current()
            .removePendingNotificationRequests(
                withIdentifiers: identifiers
            )

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
