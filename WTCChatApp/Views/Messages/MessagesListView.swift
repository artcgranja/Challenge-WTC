import SwiftUI

struct MessagesListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = MessagesViewModel()
    @State private var selectedMessage: Message?
    @State private var showingProfile = false

    var body: some View {
        NavigationView {
            ZStack {
                Theme.screenBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    FilterTabView(selectedFilter: $viewModel.selectedFilter)

                    SearchBar(text: $viewModel.searchText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                    if viewModel.isLoading && viewModel.messages.isEmpty {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.1)
                        Spacer()
                    } else if viewModel.filteredMessages.isEmpty {
                        EmptyStateView(
                            icon: "tray",
                            message: viewModel.searchText.isEmpty
                                ? "Nenhuma mensagem"
                                : "Nenhum resultado encontrado",
                            subtitle: viewModel.searchText.isEmpty
                                ? "Suas mensagens aparecerão aqui"
                                : "Tente buscar por outro termo"
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(viewModel.filteredMessages) { message in
                                    MessageRowView(message: message)
                                        .onTapGesture {
                                            selectedMessage = message
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                viewModel.deleteMessage(message)
                                            } label: {
                                                Label("Deletar", systemImage: "trash")
                                            }

                                            Button {
                                                Task { await viewModel.toggleStar(message) }
                                            } label: {
                                                Label(
                                                    message.starred ? "Desfavoritar" : "Favoritar",
                                                    systemImage: message.starred ? "star.slash" : "star.fill"
                                                )
                                            }
                                            .tint(.orange)
                                        }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                        .refreshable {
                            if let userId = authViewModel.currentProfile?.id,
                               let userTags = authViewModel.currentProfile?.tags {
                                await viewModel.refreshMessages(userId: userId, userTags: userTags)
                            }
                        }
                    }
                }
                .navigationTitle("Mensagens")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingProfile = true }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "person.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Theme.primaryGradient)
                            }
                        }
                    }

                    ToolbarItem(placement: .navigationBarLeading) {
                        if viewModel.unreadCount > 0 {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Theme.primary)
                                    .frame(width: 8, height: 8)
                                Text("\(viewModel.unreadCount) não lidas")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                if let message = selectedMessage {
                    NavigationLink(
                        destination: MessageDetailView(message: message)
                            .environmentObject(viewModel),
                        isActive: Binding(
                            get: { selectedMessage != nil },
                            set: { if !$0 { selectedMessage = nil } }
                        )
                    ) {
                        EmptyView()
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
                    .environmentObject(authViewModel)
            }
        }
        .task {
            if let userId = authViewModel.currentProfile?.id,
               let userTags = authViewModel.currentProfile?.tags {
                await viewModel.fetchMessages(userId: userId, userTags: userTags)
            }
        }
        .onDisappear {
            Task { await viewModel.cleanup() }
        }
    }
}

// MARK: - Filter Tab View

struct FilterTabView: View {
    @Binding var selectedFilter: MessagesViewModel.MessageFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MessagesViewModel.MessageFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        icon: iconForFilter(filter),
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func iconForFilter(_ filter: MessagesViewModel.MessageFilter) -> String? {
        switch filter {
        case .all: return nil
        case .chat: return "message"
        case .campaign: return "megaphone"
        case .unread: return "circle.fill"
        case .starred: return "star.fill"
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .semibold))
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                Group {
                    if isSelected {
                        Theme.primaryGradient
                    } else {
                        LinearGradient(
                            colors: [Theme.cardBackground],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .cornerRadius(Theme.cornerLG)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerLG)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
    }
}

// MARK: - Message Row View

struct MessageRowView: View {
    let message: Message

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(message.type == .campaign ? Theme.campaignGradient : Theme.primaryGradient)
                    .frame(width: Theme.avatarMD, height: Theme.avatarMD)

                Image(systemName: message.type == .campaign ? "megaphone.fill" : "message.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .top) {
                    Text(message.content.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    HStack(spacing: 6) {
                        if message.starred {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                        }

                        if !message.isRead {
                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 9, height: 9)
                        }
                    }
                }

                Text(message.content.body)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Text(message.createdAt.timeAgo())
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(Theme.cornerMD)
        .modifier(CardShadow())
        .opacity(message.isRead ? 0.88 : 1.0)
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)

            TextField("Buscar mensagens...", text: $text)
                .font(.subheadline)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerSM)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let message: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 14) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.primary.opacity(0.08))
                    .frame(width: 100, height: 100)

                Image(systemName: icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Theme.primaryGradient)
            }

            Text(message)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Date Extension

extension Date {
    func timeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

struct MessagesListView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesListView()
            .environmentObject(AuthViewModel())
    }
}
