//
//  DeeplinkHandler.swift
//  WTCChatApp
//
//  Created by WTC Challenge
//

import Foundation
import SwiftUI
import UIKit

class DeeplinkHandler: ObservableObject {
    @Published var activeDeeplink: DeeplinkDestination?

    enum DeeplinkDestination: Equatable {
        case products
        case profile
        case orders
        case collection
        case message(UUID)
    }

    func handle(action: String) -> Bool {
        // Handle deeplink:// actions
        if action.hasPrefix("deeplink://") {
            return handleDeeplink(action)
        }
        // Handle copy: actions
        else if action.hasPrefix("copy:") {
            return handleCopy(action)
        }
        // Handle https:// actions
        else if action.hasPrefix("https://") || action.hasPrefix("http://") {
            return handleExternalLink(action)
        }

        return false
    }

    private func handleDeeplink(_ action: String) -> Bool {
        guard let url = URL(string: action),
              let host = url.host else {
            return false
        }

        switch host {
        case "products":
            activeDeeplink = .products
            return true
        case "profile":
            activeDeeplink = .profile
            return true
        case "orders":
            activeDeeplink = .orders
            return true
        case "collection":
            activeDeeplink = .collection
            return true
        case "message":
            if let messageIdString = url.pathComponents.last,
               let messageId = UUID(uuidString: messageIdString) {
                activeDeeplink = .message(messageId)
                return true
            }
            return false
        default:
            return false
        }
    }

    private func handleCopy(_ action: String) -> Bool {
        let text = action.replacingOccurrences(of: "copy:", with: "")
        UIPasteboard.general.string = text

        // Show toast notification
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowToast"),
            object: nil,
            userInfo: ["message": "Copiado: \(text)"]
        )

        return true
    }

    private func handleExternalLink(_ action: String) -> Bool {
        guard let url = URL(string: action) else {
            return false
        }

        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }

        return true
    }
}

// Toast View for feedback
struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool

    var body: some View {
        VStack {
            Spacer()
            if isShowing {
                Text(message)
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                isShowing = false
                            }
                        }
                    }
            }
        }
        .padding(.bottom, 50)
    }
}
