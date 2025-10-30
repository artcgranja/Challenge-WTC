//
//  MessagesViewModel.swift
//  WTCChatApp
//
//  Created by WTC Challenge
//

import Foundation
import SwiftUI
import Combine

@MainActor
class MessagesViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var filteredMessages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedFilter: MessageFilter = .all
    @Published var unreadCount = 0

    private let supabaseService = SupabaseService.shared
    private let realtimeService = RealtimeService.shared
    private let notificationService = NotificationService.shared
    private var cancellables = Set<AnyCancellable>()

    enum MessageFilter: String, CaseIterable {
        case all = "Todas"
        case chat = "Chat"
        case campaign = "Campanhas"
        case unread = "Não Lidas"
        case starred = "Favoritas"
    }

    init() {
        setupSearchAndFilter()
        setupRealtimeSubscription()
    }

    // MARK: - Setup

    private func setupSearchAndFilter() {
        // Combine search and filter
        Publishers.CombineLatest($messages, $searchText)
            .combineLatest($selectedFilter)
            .map { (messagesAndSearch, filter) -> [Message] in
                let (messages, search) = messagesAndSearch
                var filtered = messages

                // Apply filter
                switch filter {
                case .all:
                    break
                case .chat:
                    filtered = filtered.filter { $0.type == .chat }
                case .campaign:
                    filtered = filtered.filter { $0.type == .campaign }
                case .unread:
                    filtered = filtered.filter { !$0.isRead }
                case .starred:
                    filtered = filtered.filter { $0.starred }
                }

                // Apply search
                if !search.isEmpty {
                    filtered = filtered.filter { message in
                        message.content.title.localizedCaseInsensitiveContains(search) ||
                        message.content.body.localizedCaseInsensitiveContains(search)
                    }
                }

                return filtered
            }
            .assign(to: &$filteredMessages)

        // Calculate unread count
        $messages
            .map { messages in
                messages.filter { !$0.isRead }.count
            }
            .assign(to: &$unreadCount)

        // Update badge
        $unreadCount
            .sink { [weak self] count in
                self?.notificationService.updateBadgeCount(count)
            }
            .store(in: &cancellables)
    }

    private func setupRealtimeSubscription() {
        // Listen for new messages from realtime
        realtimeService.$newMessage
            .compactMap { $0 }
            .sink { [weak self] newMessage in
                self?.handleNewMessage(newMessage)
            }
            .store(in: &cancellables)
    }

    // MARK: - Fetch Messages

    func fetchMessages(userId: UUID, userTags: [String]) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            messages = try await supabaseService.fetchMessages(userId: userId, userTags: userTags)

            // Subscribe to realtime updates
            try await realtimeService.subscribeToMessages(userId: userId, userTags: userTags)
        } catch {
            errorMessage = "Erro ao carregar mensagens: \(error.localizedDescription)"
            print("Fetch messages error: \(error)")
        }
    }

    func refreshMessages(userId: UUID, userTags: [String]) async {
        await fetchMessages(userId: userId, userTags: userTags)
    }

    // MARK: - Handle New Message

    private func handleNewMessage(_ newMessage: Message) {
        // Add to list if not already present
        if !messages.contains(where: { $0.id == newMessage.id }) {
            messages.insert(newMessage, at: 0)

            // Show in-app notification
            notificationService.showInAppNotification(
                title: newMessage.content.title,
                body: newMessage.content.body,
                messageId: newMessage.id
            )

            // Schedule local notification if app in background
            notificationService.scheduleLocalNotification(
                title: newMessage.content.title,
                body: newMessage.content.body,
                messageId: newMessage.id
            )
        }
    }

    // MARK: - Message Actions

    func markAsRead(_ message: Message) async {
        guard !message.isRead else { return }

        do {
            try await supabaseService.markMessageAsRead(messageId: message.id)

            // Update local state
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                messages[index].readAt = Date()
            }
        } catch {
            print("Error marking message as read: \(error)")
        }
    }

    func toggleStar(_ message: Message) async {
        let newStarredState = !message.starred

        do {
            try await supabaseService.toggleMessageStar(messageId: message.id, starred: newStarredState)

            // Update local state
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                messages[index].starred = newStarredState
            }
        } catch {
            errorMessage = "Erro ao favoritar mensagem"
            print("Error toggling star: \(error)")
        }
    }

    func deleteMessage(_ message: Message) {
        // Remove from local state
        messages.removeAll { $0.id == message.id }
    }

    // MARK: - Cleanup

    func cleanup() async {
        await realtimeService.unsubscribeFromMessages()
    }
}
