import SwiftUI

struct MessageDetailView: View {
    @EnvironmentObject var viewModel: MessagesViewModel
    @StateObject private var deeplinkHandler = DeeplinkHandler()
    @Environment(\.dismiss) var dismiss

    @State private var showToast = false
    @State private var toastMessage = ""

    let message: Message

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Banner image
                if let imageUrl = message.content.imageUrl,
                   let url = URL(string: imageUrl) {
                    AsyncImage(url: url, transaction: Transaction(animation: .easeInOut)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Theme.cardBackground)
                                .frame(height: 220)
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 220)
                                .clipped()
                                .transition(.opacity)
                        case .failure:
                            Rectangle()
                                .fill(Theme.cardBackground)
                                .frame(height: 220)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 36, weight: .light))
                                        .foregroundStyle(.secondary)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 20) {
                    // Type badge
                    HStack(spacing: 6) {
                        Image(systemName: message.type == .campaign ? "megaphone.fill" : "message.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text(message.type == .campaign ? "CAMPANHA" : "MENSAGEM")
                            .font(.system(size: 11, weight: .bold))
                            .kerning(0.5)
                    }
                    .foregroundColor(message.type == .campaign ? Theme.campaignOrange : Theme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        (message.type == .campaign ? Theme.campaignOrange : Theme.primary).opacity(0.1)
                    )
                    .cornerRadius(6)

                    Text(message.content.title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.primary)

                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text(message.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)

                    Rectangle()
                        .fill(Color.gray.opacity(0.12))
                        .frame(height: 1)

                    // Body
                    Text(message.content.body)
                        .font(.body)
                        .lineSpacing(4)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Action buttons
                    if let buttons = message.content.buttons, !buttons.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Ações")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            ForEach(buttons) { button in
                                ActionButtonView(button: button) {
                                    handleAction(button.action)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(20)

                Spacer(minLength: 50)
            }
        }
        .background(Color(UIColor.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task { await viewModel.toggleStar(message) }
                }) {
                    Image(systemName: message.starred ? "star.fill" : "star")
                        .foregroundColor(message.starred ? .orange : .gray)
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .task {
            await viewModel.markAsRead(message)
        }
        .overlay(
            ToastView(message: toastMessage, isShowing: $showToast)
        )
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowToast"))) { notification in
            if let message = notification.userInfo?["message"] as? String {
                toastMessage = message
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showToast = true
                }
            }
        }
    }

    private func handleAction(_ action: String) {
        _ = deeplinkHandler.handle(action: action)
    }
}

// MARK: - Action Button View

struct ActionButtonView: View {
    let button: ActionButton
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: iconForAction(button.action))
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 20)

                Text(button.label)
                    .font(.system(size: 15, weight: .semibold))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .background(gradientForAction(button.action))
            .cornerRadius(Theme.cornerMD)
            .modifier(CardShadow())
        }
    }

    private func iconForAction(_ action: String) -> String {
        if action.hasPrefix("deeplink://") {
            return "arrow.right.circle.fill"
        } else if action.hasPrefix("copy:") {
            return "doc.on.doc.fill"
        } else if action.hasPrefix("http") {
            return "safari.fill"
        }
        return "hand.tap.fill"
    }

    private func gradientForAction(_ action: String) -> LinearGradient {
        if action.hasPrefix("deeplink://") {
            return Theme.primaryGradient
        } else if action.hasPrefix("copy:") {
            return LinearGradient(colors: [Theme.success, Theme.accent], startPoint: .leading, endPoint: .trailing)
        } else if action.hasPrefix("http") {
            return Theme.campaignGradient
        }
        return LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
    }
}

struct MessageDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleMessage = Message(
            type: .campaign,
            content: MessageContent(
                title: "Black Friday 2025",
                body: "Aproveite 50% de desconto em todos os produtos! Esta é uma promoção exclusiva para nossos clientes VIP.",
                imageUrl: "https://placehold.co/600x400/png",
                buttons: [
                    ActionButton(label: "Ver Ofertas", action: "deeplink://products"),
                    ActionButton(label: "Copiar Cupom: BF50", action: "copy:BF50"),
                    ActionButton(label: "Visitar Site", action: "https://wtc.com")
                ]
            )
        )

        return NavigationView {
            MessageDetailView(message: sampleMessage)
                .environmentObject(MessagesViewModel())
        }
    }
}
