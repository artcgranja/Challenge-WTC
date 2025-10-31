//
//  SupabaseService.swift
//  WTCChatApp
//
//  Created by WTC Challenge
//

import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: Constants.supabaseURL)!,
            supabaseKey: Constants.supabaseAnonKey
        )
    }

    // MARK: - Authentication

    func signIn(email: String, password: String) async throws -> User {
        let response = try await client.auth.signIn(email: email, password: password)
        return response.user
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func getCurrentUser() async throws -> User? {
        return try await client.auth.session.user
    }

    func getCurrentSession() async -> Session? {
        return try? await client.auth.session
    }

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    // MARK: - Profile

    func fetchProfile(userId: UUID) async throws -> Profile {
        let response: Profile = try await client
            .from(Constants.Tables.profiles)
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        return response
    }

    func updateProfile(_ profile: Profile) async throws {
        try await client
            .from(Constants.Tables.profiles)
            .update(profile)
            .eq("id", value: profile.id.uuidString)
            .execute()
    }

    // MARK: - Messages

    func fetchMessages(userId: UUID, userTags: [String]) async throws -> [Message] {
        // Fetch messages where user is recipient OR user has matching tags
        let response: [Message] = try await client
            .from(Constants.Tables.messages)
            .select()
            .or("recipient_id.eq.\(userId.uuidString),segment_tags.ov.{\(userTags.joined(separator: ","))}")
            .order("created_at", ascending: false)
            .execute()
            .value

        return response
    }

    func markMessageAsRead(messageId: UUID) async throws {
        try await client
            .from(Constants.Tables.messages)
            .update(["read_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: messageId.uuidString)
            .execute()
    }

    func toggleMessageStar(messageId: UUID, starred: Bool) async throws {
        try await client
            .from(Constants.Tables.messages)
            .update(["starred": starred])
            .eq("id", value: messageId.uuidString)
            .execute()
    }

    // MARK: - Notifications

    func fetchNotifications(userId: UUID) async throws -> [AppNotification] {
        let response: [AppNotification] = try await client
            .from(Constants.Tables.notifications)
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return response
    }

    func markNotificationAsRead(notificationId: UUID) async throws {
        try await client
            .from(Constants.Tables.notifications)
            .update(["read": true])
            .eq("id", value: notificationId.uuidString)
            .execute()
    }

    func createNotification(userId: UUID, title: String, body: String, type: String, messageId: UUID? = nil) async throws {
        let notification = AppNotification(
            userId: userId,
            title: title,
            body: body,
            type: type,
            messageId: messageId
        )

        try await client
            .from(Constants.Tables.notifications)
            .insert(notification)
            .execute()
    }
}
