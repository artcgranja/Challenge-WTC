//
//  MessageDetailView.swift
//  WTCChatApp
//
//  Created by WTC Challenge
//

import SwiftUI

struct MessageDetailView: View {
    @EnvironmentObject var viewModel: MessagesViewModel
    @StateObject private var deeplinkHandler = DeeplinkHandler()
    @Environment(\.dismiss) var dismiss

    @State private var showToast = false
    @State private var toastMessage = ""

    let message: Message

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Banner image (if exists)
                if let imageUrl = message.content.imageUrl,
                   let url = URL(string: imageUrl) {
                    AsyncImage(url: url, transaction: Transaction(animation: .easeInOut)) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                                .frame(height: 200)
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                                .transition(.opacity)
                        case .failure:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                                .frame(height: 200)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .cornerRadius(12)
                    .shadow(radius: 5)
                }

                // Title
                Text(message.content.title)
                    .font(.title)
                    .fontWeight(.bold)

                // Metadata
                HStack {
                    Label(
                        message.type == .campaign ? "Campanha" : "Mensagem",
                        systemImage: message.type == .campaign ? "megaphone" : "message"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)

                    Spacer()

                    Label(
                        message.createdAt.formatted(date: .abbreviated, time: .shortened),
                        systemImage: "clock"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Divider()

                // Body
                Text(message.content.body)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                // Action buttons
                if let buttons = message.content.buttons, !buttons.isEmpty {
                    VStack(spacing: 12) {
                        Text("Ações")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(buttons) { button in
                            ActionButtonView(button: button) {
                                handleAction(button.action)
                            }
                        }
                    }
                    .padding(.top, 8)
                }

                Spacer(minLength: 50)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await viewModel.toggleStar(message)
                    }
                }) {
                    Image(systemName: message.starred ? "star.fill" : "star")
                        .foregroundColor(message.starred ? .yellow : .gray)
                }
            }
        }
        .task {
            // Mark as read when view appears
            await viewModel.markAsRead(message)
        }
        .overlay(
            ToastView(message: toastMessage, isShowing: $showToast)
        )
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowToast"))) { notification in
            if let message = notification.userInfo?["message"] as? String {
                toastMessage = message
                showToast = true
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
            HStack {
                Text(button.label)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: iconForAction(button.action))
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: gradientForAction(button.action)),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
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

    private func gradientForAction(_ action: String) -> [Color] {
        if action.hasPrefix("deeplink://") {
            return [Color.blue, Color.purple]
        } else if action.hasPrefix("copy:") {
            return [Color.green, Color.teal]
        } else if action.hasPrefix("http") {
            return [Color.orange, Color.red]
        }
        return [Color.gray, Color.gray]
    }
}

// MARK: - Preview

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
