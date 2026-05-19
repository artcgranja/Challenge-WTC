import Foundation
import UserNotifications
import SwiftUI

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var shouldShowInAppNotification = false
    @Published var currentInAppNotification: InAppNotificationData?

    override private init() {
        super.init()
    }

    // MARK: - Permission

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Local Notifications

    func scheduleLocalNotification(title: String, body: String, messageId: UUID? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        if let messageId = messageId {
            content.userInfo = ["messageId": messageId.uuidString]
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    // MARK: - In-App Notifications

    func showInAppNotification(title: String, body: String, messageId: UUID? = nil) {
        DispatchQueue.main.async {
            self.currentInAppNotification = InAppNotificationData(
                title: title,
                body: body,
                messageId: messageId
            )
            self.shouldShowInAppNotification = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.dismissInAppNotification()
            }
        }
    }

    func dismissInAppNotification() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            shouldShowInAppNotification = false
            currentInAppNotification = nil
        }
    }

    // MARK: - Badge Management

    func updateBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            if #available(iOS 16.0, *) {
                UNUserNotificationCenter.current().setBadgeCount(count)
            } else {
                UIApplication.shared.applicationIconBadgeNumber = count
            }
        }
    }

    func clearBadge() {
        updateBadgeCount(0)
    }
}

// MARK: - In-App Notification Data

struct InAppNotificationData: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let messageId: UUID?
}

// MARK: - In-App Notification View

struct InAppNotificationView: View {
    let notification: InAppNotificationData
    let onTap: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: "bell.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(notification.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text(notification.body)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .background(Theme.primaryGradient)
        .cornerRadius(Theme.cornerMD)
        .modifier(ElevatedShadow())
        .padding(.horizontal, 16)
        .onTapGesture {
            onTap()
        }
    }
}
