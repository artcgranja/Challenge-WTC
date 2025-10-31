//
//  NotificationsViewModel.swift
//  WTCChatApp
//
//  Created by WTC Challenge
//

import Foundation
import SwiftUI
import Combine

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var unreadCount = 0

    private let supabaseService = SupabaseService.shared
    private let realtimeService = RealtimeService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupRealtimeSubscription()
        setupUnreadCount()
    }

    // MARK: - Setup

    private func setupRealtimeSubscription() {
        // Listen for new notifications from realtime
        realtimeService.$newNotification
            .compactMap { $0 }
            .sink { [weak self] newNotification in
                self?.handleNewNotification(newNotification)
            }
            .store(in: &cancellables)
    }

    private func setupUnreadCount() {
        $notifications
            .map { notifications in
                notifications.filter { !$0.read }.count
            }
            .assign(to: &$unreadCount)
    }

    // MARK: - Fetch Notifications

    func fetchNotifications(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            notifications = try await supabaseService.fetchNotifications(userId: userId)

            // Subscribe to realtime updates
            try await realtimeService.subscribeToNotifications(userId: userId)
        } catch {
            errorMessage = "Erro ao carregar notificações: \(error.localizedDescription)"
            print("Fetch notifications error: \(error)")
        }
    }

    func refreshNotifications(userId: UUID) async {
        await fetchNotifications(userId: userId)
    }

    // MARK: - Handle New Notification

    private func handleNewNotification(_ newNotification: AppNotification) {
        // Add to list if not already present
        if !notifications.contains(where: { $0.id == newNotification.id }) {
            notifications.insert(newNotification, at: 0)
        }
    }

    // MARK: - Notification Actions

    func markAsRead(_ notification: AppNotification) async {
        guard !notification.read else { return }

        do {
            try await supabaseService.markNotificationAsRead(notificationId: notification.id)

            // Update local state
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index].read = true
            }
        } catch {
            print("Error marking notification as read: \(error)")
        }
    }

    func markAllAsRead(userId: UUID) async {
        for notification in notifications where !notification.read {
            await markAsRead(notification)
        }
    }

    func deleteNotification(_ notification: AppNotification) {
        // Remove from local state
        notifications.removeAll { $0.id == notification.id }
    }

    // MARK: - Cleanup

    func cleanup() async {
        await realtimeService.unsubscribeFromNotifications()
    }
}
