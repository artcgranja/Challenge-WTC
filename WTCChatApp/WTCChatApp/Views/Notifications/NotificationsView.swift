//
//  NotificationsView.swift
//  WTCChatApp
//
//  Created by WTC Challenge
//

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = NotificationsViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.notifications.isEmpty {
                    EmptyStateView(
                        icon: "bell.slash",
                        message: "Nenhuma notificação"
                    )
                } else {
                    List {
                        ForEach(viewModel.notifications) { notification in
                            NotificationRowView(notification: notification)
                                .onTapGesture {
                                    Task {
                                        await viewModel.markAsRead(notification)

                                        // Navigate to message if available
                                        if let messageId = notification.messageId {
                                            // TODO: Navigate to message detail
                                            print("Navigate to message: \(messageId)")
                                        }
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.deleteNotification(notification)
                                    } label: {
                                        Label("Deletar", systemImage: "trash")
                                    }
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        if let userId = authViewModel.currentUser?.id {
                            await viewModel.refreshNotifications(userId: userId)
                        }
                    }
                }
            }
            .navigationTitle("Notificações")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.unreadCount > 0 {
                        Button("Marcar todas como lidas") {
                            Task {
                                if let userId = authViewModel.currentUser?.id {
                                    await viewModel.markAllAsRead(userId: userId)
                                }
                            }
                        }
                        .font(.caption)
                    }
                }
            }
        }
        .task {
            if let userId = authViewModel.currentUser?.id {
                await viewModel.fetchNotifications(userId: userId)
            }
        }
        .onDisappear {
            Task {
                await viewModel.cleanup()
            }
        }
    }
}

// MARK: - Notification Row View

struct NotificationRowView: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(notification.read ? Color.gray.opacity(0.3) : Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: iconForType(notification.type))
                    .font(.body)
                    .foregroundColor(notification.read ? .gray : .blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    if !notification.read {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                }

                Text(notification.body)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Text(notification.createdAt.timeAgo())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(notification.read ? Color.clear : Color.blue.opacity(0.05))
        .cornerRadius(12)
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "message":
            return "message.fill"
        case "campaign":
            return "megaphone.fill"
        case "system":
            return "info.circle.fill"
        default:
            return "bell.fill"
        }
    }
}

// MARK: - Preview

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
            .environmentObject(AuthViewModel())
    }
}
