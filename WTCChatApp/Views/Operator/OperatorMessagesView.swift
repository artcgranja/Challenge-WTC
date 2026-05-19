import SwiftUI

struct OperatorMessagesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @EnvironmentObject var crmViewModel: CRMViewModel
    @State private var showComposeSheet = false
    @State private var selectedMessage: Message?

    var body: some View {
        NavigationView {
            ZStack {
                Theme.screenBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    messageFilterChips

                    SearchBar(text: $campaignViewModel.messageSearchText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                    if campaignViewModel.isLoading && campaignViewModel.sentMessages.isEmpty {
                        Spacer()
                        ProgressView().scaleEffect(1.1)
                        Spacer()
                    } else if campaignViewModel.filteredSentMessages.isEmpty {
                        EmptyStateView(
                            icon: "paperplane",
                            message: "Nenhuma mensagem enviada",
                            subtitle: "Suas mensagens aparecerão aqui"
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(campaignViewModel.filteredSentMessages) { message in
                                    SentMessageRowView(message: message)
                                        .onTapGesture { selectedMessage = message }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                        .refreshable {
                            await campaignViewModel.fetchSentMessages()
                        }
                    }
                }
                .navigationTitle("Mensagens")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showComposeSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Nova")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Theme.primaryGradient)
                            .cornerRadius(Theme.cornerMD)
                        }
                    }
                }

                NavigationLink(
                    destination: Group {
                        if let message = selectedMessage {
                            MessageDetailView(message: message)
                                .environmentObject(MessagesViewModel())
                        }
                    },
                    isActive: Binding(
                        get: { selectedMessage != nil },
                        set: { if !$0 { selectedMessage = nil } }
                    )
                ) { EmptyView() }
            }
        }
        .sheet(isPresented: $showComposeSheet) {
            ComposeMessageSheet()
                .environmentObject(campaignViewModel)
                .environmentObject(crmViewModel)
        }
        .task {
            await campaignViewModel.fetchSentMessages()
        }
    }

    private var messageFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach([MessagesViewModel.MessageFilter.all, .chat, .campaign], id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        icon: filter == .chat ? "message" : (filter == .campaign ? "megaphone" : nil),
                        isSelected: campaignViewModel.messageFilter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            campaignViewModel.messageFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

struct SentMessageRowView: View {
    let message: Message

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(message.type == .campaign
                          ? LinearGradient(colors: [Theme.campaignOrange.opacity(0.15), Theme.campaignRed.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                          : LinearGradient(colors: [Theme.primary.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: 40, height: 40)
                Image(systemName: message.type == .campaign ? "megaphone.fill" : "message.fill")
                    .font(.system(size: 16))
                    .foregroundColor(message.type == .campaign ? Theme.campaignOrange : Theme.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(message.content.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                    Text(message.createdAt.timeAgo())
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Text(message.content.body)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(message.type == .campaign ? "CAMPANHA" : "CHAT")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(message.type == .campaign ? Theme.warning : Theme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background((message.type == .campaign ? Theme.warning : Theme.accent).opacity(0.1))
                        .cornerRadius(8)

                    if let tags = message.segmentTags, !tags.isEmpty {
                        Text("→ Segmento: \(tags.joined(separator: ", "))")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else if message.recipientId != nil {
                        Text("→ Cliente")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if message.isRead {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                            Text("Lida")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(Theme.success)
                    } else {
                        HStack(spacing: 2) {
                            Circle().stroke(Color.secondary, lineWidth: 1).frame(width: 8, height: 8)
                            Text("Não lida")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(Theme.cornerMD)
        .modifier(CardShadow())
    }
}
