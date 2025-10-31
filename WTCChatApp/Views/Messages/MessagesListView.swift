//
//  MessagesListView.swift
//  WTCChatApp
//
//  Created by WTC Challenge
//

import SwiftUI

struct MessagesListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = MessagesViewModel()
    @State private var selectedMessage: Message?
    @State private var showingProfile = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Filter tabs
                    FilterTabView(selectedFilter: $viewModel.selectedFilter)

                    // Search bar
                    SearchBar(text: $viewModel.searchText)
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                    // Messages list
                    if viewModel.isLoading && viewModel.messages.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.filteredMessages.isEmpty {
                        EmptyStateView(
                            icon: "tray",
                            message: viewModel.searchText.isEmpty ? "Nenhuma mensagem" : "Nenhum resultado encontrado"
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
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
                                                Task {
                                                    await viewModel.toggleStar(message)
                                                }
                                            } label: {
                                                Label(
                                                    message.starred ? "Desfavoritar" : "Favoritar",
                                                    systemImage: message.starred ? "star.slash" : "star.fill"
                                                )
                                            }
                                            .tint(.yellow)
                                        }
                                }
                            }
                        }
                        .refreshable {
                            if let userId = authViewModel.currentUser?.id,
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
                        Button(action: {
                            showingProfile = true
                        }) {
                            Image(systemName: "person.circle")
                                .font(.title3)
                        }
                    }

                    ToolbarItem(placement: .navigationBarLeading) {
                        if viewModel.unreadCount > 0 {
                            Text("\(viewModel.unreadCount) não lidas")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Message detail navigation
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
            if let userId = authViewModel.currentUser?.id,
               let userTags = authViewModel.currentProfile?.tags {
                await viewModel.fetchMessages(userId: userId, userTags: userTags)
            }
        }
        .onDisappear {
            Task {
                await viewModel.cleanup()
            }
        }
    }
}

// MARK: - Filter Tab View

struct FilterTabView: View {
    @Binding var selectedFilter: MessagesViewModel.MessageFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MessagesViewModel.MessageFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        gradient: Gradient(colors: [Color(UIColor.secondarySystemBackground)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
        }
    }
}

// MARK: - Message Row View

struct MessageRowView: View {
    let message: Message

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        message.type == .campaign ?
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange, Color.red]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: message.type == .campaign ? "megaphone.fill" : "message.fill")
                    .font(.title3)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(message.content.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    if message.starred {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }

                    if !message.isRead {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 10, height: 10)
                    }
                }

                Text(message.content.body)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Text(message.createdAt.timeAgo())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(0)
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Buscar mensagens", text: $text)
                .textFieldStyle(PlainTextFieldStyle())

            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
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

// MARK: - Preview

struct MessagesListView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesListView()
            .environmentObject(AuthViewModel())
    }
}
