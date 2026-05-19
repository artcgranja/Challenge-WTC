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

    private let apiService = APIService.shared
    private let webSocketService = WebSocketService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupRealtimeSubscription()
        setupUnreadCount()
    }

    // MARK: - Setup

    private func setupRealtimeSubscription() {
        webSocketService.$newNotification
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
            notifications = try await apiService.fetchNotifications()
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
        if !notifications.contains(where: { $0.id == newNotification.id }) {
            notifications.insert(newNotification, at: 0)
        }
    }

    // MARK: - Notification Actions

    func markAsRead(_ notification: AppNotification) async {
        guard !notification.read else { return }

        do {
            try await apiService.markNotificationAsRead(notificationId: notification.id)

            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index].read = true
            }
        } catch {
            print("Error marking notification as read: \(error)")
        }
    }

    func markAllAsRead(userId: UUID) async {
        do {
            try await apiService.markAllNotificationsAsRead()
            for i in notifications.indices {
                notifications[i].read = true
            }
        } catch {
            print("Error marking all as read: \(error)")
        }
    }

    func deleteNotification(_ notification: AppNotification) {
        notifications.removeAll { $0.id == notification.id }
    }

    // MARK: - Cleanup

    func cleanup() async {
        // WebSocket cleanup handled by WebSocketService
    }
}
