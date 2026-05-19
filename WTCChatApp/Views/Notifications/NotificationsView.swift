import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = NotificationsViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Theme.screenBackground.ignoresSafeArea()

                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    ProgressView()
                        .scaleEffect(1.1)
                } else if viewModel.notifications.isEmpty {
                    EmptyStateView(
                        icon: "bell.slash",
                        message: "Nenhuma notificação",
                        subtitle: "Você será notificado sobre novas mensagens"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.notifications) { notification in
                                NotificationRowView(notification: notification)
                                    .onTapGesture {
                                        Task {
                                            await viewModel.markAsRead(notification)
                                            if let messageId = notification.messageId {
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
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .refreshable {
                        if let userId = authViewModel.currentProfile?.id {
                            await viewModel.refreshNotifications(userId: userId)
                        }
                    }
                }
            }
            .navigationTitle("Notificações")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("Fechar").fontWeight(.medium)
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.unreadCount > 0 {
                        Button {
                            Task {
                                if let userId = authViewModel.currentProfile?.id {
                                    await viewModel.markAllAsRead(userId: userId)
                                }
                            }
                        } label: {
                            Text("Marcar todas")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Theme.primary)
                        }
                    }
                }
            }
        }
        .task {
            if let userId = authViewModel.currentProfile?.id {
                await viewModel.fetchNotifications(userId: userId)
            }
        }
        .onDisappear {
            Task { await viewModel.cleanup() }
        }
    }
}

// MARK: - Notification Row View

struct NotificationRowView: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        notification.read
                            ? Color.gray.opacity(0.1)
                            : Theme.primary.opacity(0.12)
                    )
                    .frame(width: Theme.avatarSM, height: Theme.avatarSM)

                Image(systemName: iconForType(notification.type))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(notification.read ? .gray : Theme.primary)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .top) {
                    Text(notification.title)
                        .font(.system(size: 15, weight: notification.read ? .medium : .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    if !notification.read {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 8, height: 8)
                    }
                }

                Text(notification.body)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Text(notification.createdAt.timeAgo())
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.top, 1)
            }
        }
        .padding(14)
        .background(
            notification.read
                ? Color(UIColor.systemBackground)
                : Theme.primary.opacity(0.03)
        )
        .cornerRadius(Theme.cornerMD)
        .modifier(CardShadow())
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "message": return "message.fill"
        case "campaign": return "megaphone.fill"
        case "system": return "info.circle.fill"
        default: return "bell.fill"
        }
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
            .environmentObject(AuthViewModel())
    }
}
