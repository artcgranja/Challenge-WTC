//
//  RealtimeService.swift
//  WTCChatApp
//
//  Created by WTC Challenge
//

import Foundation
import Supabase
import Combine

class RealtimeService: ObservableObject {
    static let shared = RealtimeService()

    private var messagesChannel: RealtimeChannel?
    private var notificationsChannel: RealtimeChannel?

    @Published var newMessage: Message?
    @Published var newNotification: AppNotification?

    private init() {}

    // MARK: - Messages Subscription

    func subscribeToMessages(userId: UUID, userTags: [String]) async throws {
        let client = SupabaseService.shared.client

        messagesChannel = await client.channel("messages-channel")

        // Subscribe to INSERT events on messages table
        await messagesChannel?.on(.insert, table: Constants.Tables.messages) { [weak self] payload in
            guard let self = self else { return }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                decoder.keyDecodingStrategy = .convertFromSnakeCase

                let message = try decoder.decode(Message.self, from: JSONSerialization.data(withJSONObject: payload.record))

                // Check if message is for this user
                if message.recipientId == userId || self.hasMatchingTags(message.segmentTags, userTags: userTags) {
                    DispatchQueue.main.async {
                        self.newMessage = message
                    }
                }
            } catch {
                print("Error decoding message: \(error)")
            }
        }

        await messagesChannel?.subscribe()
    }

    func unsubscribeFromMessages() async {
        await messagesChannel?.unsubscribe()
        messagesChannel = nil
    }

    // MARK: - Notifications Subscription

    func subscribeToNotifications(userId: UUID) async throws {
        let client = SupabaseService.shared.client

        notificationsChannel = await client.channel("notifications-channel")

        // Subscribe to INSERT events on notifications table
        await notificationsChannel?.on(.insert, table: Constants.Tables.notifications) { [weak self] payload in
            guard let self = self else { return }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                decoder.keyDecodingStrategy = .convertFromSnakeCase

                let notification = try decoder.decode(AppNotification.self, from: JSONSerialization.data(withJSONObject: payload.record))

                // Check if notification is for this user
                if notification.userId == userId {
                    DispatchQueue.main.async {
                        self.newNotification = notification
                    }
                }
            } catch {
                print("Error decoding notification: \(error)")
            }
        }

        await notificationsChannel?.subscribe()
    }

    func unsubscribeFromNotifications() async {
        await notificationsChannel?.unsubscribe()
        notificationsChannel = nil
    }

    // MARK: - Helper Methods

    private func hasMatchingTags(_ messageTags: [String]?, userTags: [String]) -> Bool {
        guard let messageTags = messageTags, !messageTags.isEmpty else {
            return false
        }

        return !Set(messageTags).isDisjoint(with: Set(userTags))
    }

    func cleanup() async {
        await unsubscribeFromMessages()
        await unsubscribeFromNotifications()
    }
}
